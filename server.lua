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

-- Verify database tables and columns
local function VerifyDatabase()
    MySQL.Async.fetchAll("SHOW TABLES LIKE 'player_loans'", {}, function(result)
        if #result == 0 then
            DebugPrint("[ERROR] Table 'player_loans' does not exist in the database.", "error")
        else
            DebugPrint("[INFO] Table 'player_loans' exists in the database.", "info")
        end
    end)

    MySQL.Async.fetchAll("SHOW COLUMNS FROM players LIKE 'credit_score'", {}, function(result)
        if #result == 0 then
            DebugPrint("[ERROR] Column 'credit_score' does not exist in the 'players' table.", "error")
        else
            DebugPrint("[INFO] Column 'credit_score' exists in the 'players' table.", "info")
        end
    end)
end

-- Load player loans into memory
local function LoadPlayerLoans()
    MySQL.Async.fetchAll(
        'SELECT citizenid, SUM(total_debt) AS totalDebt, SUM(amount_paid) AS paidDebt FROM player_loans GROUP BY citizenid',
        {},
        function(results)
            for _, row in ipairs(results) do
                playerLoans[row.citizenid] = {
                    totalDebt = row.totalDebt or 0,
                    paidDebt = row.paidDebt or 0
                }
            end
            DebugPrint("Player loans loaded successfully.", "info")
        end
    )
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        VerifyDatabase()
        LoadPlayerLoans()
    end
end)

-- Get player credit and loans
RegisterNetEvent('bankloan:getCreditAndLoans')
AddEventHandler('bankloan:getCreditAndLoans', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    MySQL.Async.fetchScalar('SELECT credit_score FROM players WHERE citizenid = ?', { citizenid }, function(credit)
        if not credit then credit = 0 end

        MySQL.Async.fetchAll('SELECT * FROM player_loans WHERE citizenid = ?', { citizenid }, function(loans)
            TriggerClientEvent('bankloan:openLoanMenu', src, credit, loans)
            DebugPrint(string.format("Sent loan menu data to Player ID %s with Credit: %d", src, credit))
        end)
    end)
end)

-- Grant a loan to the player
RegisterNetEvent('bankloan:giveLoan')
AddEventHandler('bankloan:giveLoan', function(loanAmount, interestRate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    loanAmount = loanAmount or 0 -- Default loan amount to 0 if nil
    interestRate = interestRate or 0.05 -- Default interest rate to 5% if nil

    local citizenid = Player.PlayerData.citizenid
    local totalDebt = loanAmount * (1 + interestRate)

    MySQL.Async.insert(
        'INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, ?)',
        { citizenid, loanAmount, interestRate, totalDebt, 0 },
        function(insertId)
            if insertId then
                Player.Functions.AddMoney('bank', loanAmount, "Loan Granted")
                TriggerClientEvent('QBCore:Notify', src, "Loan granted! Amount: $" .. loanAmount, "success")
                DebugPrint(string.format("Loan successfully granted to Player ID %s. Loan Amount: %.2f, Interest Rate: %.2f%%", src, loanAmount, interestRate * 100), "info")
            else
                DebugPrint(string.format("[ERROR] Failed to grant loan for Player ID %s.", src), "error")
            end
        end
    )
end)

-- Check remaining debt
RegisterNetEvent('bankloan:checkDebt')
AddEventHandler('bankloan:checkDebt', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local totalDebt = playerLoans[citizenid] and playerLoans[citizenid].totalDebt or 0
    local paidDebt = playerLoans[citizenid] and playerLoans[citizenid].paidDebt or 0

    TriggerClientEvent('bankloan:displayDebitNotification', src, totalDebt, paidDebt)
    DebugPrint(string.format("Debt check for Player ID %s. Total Debt: %.2f, Paid Debt: %.2f", src, totalDebt, paidDebt), "info")
end)

-- Deduct paycheck for loan repayment
RegisterNetEvent('bankloan:paycheckDeduction')
AddEventHandler('bankloan:paycheckDeduction', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local loanData = playerLoans[citizenid]

    if not loanData or loanData.totalDebt <= loanData.paidDebt then
        DebugPrint("No outstanding loans for paycheck deduction.", "info")
        return
    end

    local paycheckAmount = Player.PlayerData.job.payment or 0
    local deduction = math.min(paycheckAmount * Config.PaybackPercentage, loanData.totalDebt - loanData.paidDebt)

    if deduction > 0 then
        playerLoans[citizenid].paidDebt = loanData.paidDebt + deduction

        MySQL.Async.execute('UPDATE player_loans SET amount_paid = amount_paid + ? WHERE citizenid = ?', { deduction, citizenid })
        TriggerClientEvent('QBCore:Notify', src, string.format("$%.2f deducted from your paycheck for loan repayment.", deduction), "primary")
        DebugPrint(string.format("Paycheck deduction applied for Player ID %s. Deduction: %.2f", src, deduction), "info")
    end
end)

-- Admin command to clear player debt
QBCore.Commands.Add('remove_debit', 'Remove all debt for a player', {{ name = 'id', help = 'Player ID' }}, false, function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, "Invalid Player ID", "error")
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, "Player not found", "error")
        return
    end

    local citizenid = targetPlayer.PlayerData.citizenid
    MySQL.Async.execute('DELETE FROM player_loans WHERE citizenid = ?', { citizenid })

    playerLoans[citizenid] = nil

    TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, "Your debt has been cleared.", "success")
    TriggerClientEvent('QBCore:Notify', source, "You have cleared the debt for Player ID: " .. targetId, "success")
    DebugPrint(string.format("Debt cleared for Player ID %s.", targetId), "info")
end)
