local QBCore = exports['qb-core']:GetCoreObject()

-- Table to store player loans in memory
local playerLoans = {}

-- Debug print helper function
local function DebugPrint(message, level)
    if Config.Debug then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local levels = { info = "[INFO]", warning = "[WARNING]", error = "[ERROR]" }
        local logLevel = levels[level] or "[INFO]"
        print(string.format("[%s] %s %s", timestamp, logLevel, message))
    end
end

RegisterNetEvent('bankloan:getCreditAndLoans', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    MySQL.Async.fetchScalar('SELECT credit FROM players WHERE citizenid = ?', { citizenid }, function(credit)
        if not credit then credit = 0 end

        MySQL.Async.fetchAll('SELECT * FROM player_loans WHERE citizenid = ?', { citizenid }, function(loans)
            -- Trigger client event with player credit and loan data
            TriggerClientEvent('bankloan:openLoanMenu', src, credit, loans)
            DebugPrint(string.format("Sending loan menu data to Player ID %s with Credit: %d", src, credit))
        end)
    end)
end)

-- Validate player access to prevent abuse via Lua executors
local function IsValidSource(source)
    return source ~= nil and source > 0
end

-- Secure server-side events
local function SecureEvent(source, cb)
    if not IsValidSource(source) then
        DebugPrint("Invalid source attempting to trigger event.", "warning")
        return false
    end
    if cb then cb() end
    return true
end

-- Load player loans into memory on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DebugPrint("Resource started. Loading player loans...", "info")

        MySQL.Async.fetchAll('SELECT citizenid, SUM(total_debt) AS totalDebt, SUM(amount_paid) AS paidDebt FROM player_loans GROUP BY citizenid', {}, function(results)
            for _, row in ipairs(results) do
                playerLoans[row.citizenid] = {
                    totalDebt = row.totalDebt or 0,
                    paidDebt = row.paidDebt or 0
                }
            end
            DebugPrint("Player loans loaded successfully.", "info")
        end)
    end
end)

-- Handle loan giving event
RegisterNetEvent('bankloan:giveLoan', function(loanAmount, interestRate)
    local src = source
    SecureEvent(src, function()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then
            DebugPrint("Player not found.", "error")
            return
        end

        local citizenid = Player.PlayerData.citizenid
        local totalDebt = loanAmount + (loanAmount * interestRate)

        -- Insert loan into the database
        MySQL.Async.insert('INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, ?)', {
            citizenid,
            loanAmount,
            interestRate,
            totalDebt,
            0
        }, function(insertId)
            if insertId then
                DebugPrint(string.format("Loan granted: ID=%d, Amount=%s%.2f, Interest=%s%%, Total Debt=%s%.2f", insertId, Config.CurrencySymbol, loanAmount, interestRate * 100, Config.CurrencySymbol, totalDebt), "info")

                -- Update player memory
                if not playerLoans[citizenid] then
                    playerLoans[citizenid] = { totalDebt = 0, paidDebt = 0 }
                end

                playerLoans[citizenid].totalDebt = playerLoans[citizenid].totalDebt + totalDebt

                -- Grant the loan money
                Player.Functions.AddMoney('cash', loanAmount, "Bank Loan")

                -- Notify the player
                TriggerClientEvent('QBCore:Notify', src, string.format("You received a loan of %s%.2f.", Config.CurrencySymbol, loanAmount), "success")
            else
                DebugPrint("Error inserting loan into database.", "error")
            end
        end)
    end)
end)

-- Handle debt checking event
RegisterNetEvent('bankloan:checkDebt', function()
    local src = source
    SecureEvent(src, function()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then
            DebugPrint("Player not found for debt check.", "error")
            return
        end

        local citizenid = Player.PlayerData.citizenid
        local totalDebt = playerLoans[citizenid] and playerLoans[citizenid].totalDebt or 0
        local paidDebt = playerLoans[citizenid] and playerLoans[citizenid].paidDebt or 0

        TriggerClientEvent('bankloan:displayDebitNotification', src, totalDebt, paidDebt)
        DebugPrint(string.format("Debt check for Player: %s, Total Debt: %.2f, Paid Debt: %.2f", citizenid, totalDebt, paidDebt), "info")
    end)
end)

-- Handle paycheck deductions for loan repayment
RegisterNetEvent('bankloan:paycheckDeduction', function()
    local src = source
    SecureEvent(src, function()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then
            DebugPrint("Player not found for paycheck deduction.", "error")
            return
        end

        local citizenid = Player.PlayerData.citizenid
        if not playerLoans[citizenid] or playerLoans[citizenid].totalDebt <= playerLoans[citizenid].paidDebt then
            DebugPrint("No outstanding loans for paycheck deduction.", "info")
            return
        end

        -- Calculate deduction
        local paycheckAmount = Player.PlayerData.job.payment or 0
        local deduction = math.min(paycheckAmount * Config.PaybackPercentage, playerLoans[citizenid].totalDebt - playerLoans[citizenid].paidDebt)

        if deduction > 0 then
            playerLoans[citizenid].paidDebt = playerLoans[citizenid].paidDebt + deduction

            MySQL.Async.execute('UPDATE player_loans SET amount_paid = amount_paid + ? WHERE citizenid = ?', {
                deduction,
                citizenid
            })

            DebugPrint(string.format("Paycheck deduction: Player=%s, Deduction=%s%.2f", citizenid, Config.CurrencySymbol, deduction), "info")
            TriggerClientEvent('QBCore:Notify', src, string.format("%s%.2f has been deducted from your paycheck for loan repayment.", Config.CurrencySymbol, deduction), "primary")
        end
    end)
end)

-- Admin command to remove player debt
QBCore.Commands.Add('remove_debit', 'Remove all debt for a player (Admin Only)', {{ name = 'id', help = 'Player ID' }}, true, function(source, args)
    local src = source
    SecureEvent(src, function()
        local targetId = tonumber(args[1])
        if not targetId then
            TriggerClientEvent('QBCore:Notify', src, "Invalid Player ID", "error")
            return
        end

        local targetPlayer = QBCore.Functions.GetPlayer(targetId)
        if not targetPlayer then
            TriggerClientEvent('QBCore:Notify', src, "Player not found", "error")
            return
        end

        local citizenid = targetPlayer.PlayerData.citizenid
        MySQL.Async.execute('DELETE FROM player_loans WHERE citizenid = ?', { citizenid })

        if playerLoans[citizenid] then
            playerLoans[citizenid] = nil
        end

        TriggerClientEvent('QBCore:Notify', targetId, "Your debt has been cleared.", "success")
        TriggerClientEvent('QBCore:Notify', src, "You have cleared the debt for Player ID: " .. targetId, "success")
        DebugPrint("Debt cleared for Player: " .. citizenid, "info")
    end)
end, 'admin')

-- Handle player disconnects
AddEventHandler('playerDropped', function(reason)
    local src = source
    SecureEvent(src, function()
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            DebugPrint(string.format("Player disconnected: ID=%d, Reason=%s", src, reason), "info")
        end
    end)
end)
