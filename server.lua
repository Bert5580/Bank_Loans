local QBCore = exports['qb-core']:GetCoreObject()

local playerLoans = {}

-- Debug Print Helper
local function DebugPrint(message, level)
    if Config.Debug then
        local timestamp = "[" .. math.floor(GetGameTimer() / 1000) .. "s]"
        local levels = { info = "[INFO]", warning = "[WARNING]", error = "[ERROR]" }
        local logLevel = levels[level] or "[INFO]"
        print(string.format("%s %s %s", timestamp, logLevel, message))
    end
end

-- Load all player loans into memory
local function LoadPlayerLoans()
    MySQL.Async.fetchAll(
        'SELECT citizenid, SUM(total_debt) AS totalDebt, SUM(amount_paid) AS paidDebt FROM player_loans GROUP BY citizenid',
        {}, function(results)
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

RegisterNetEvent('bankloan:checkDebt')
AddEventHandler('bankloan:checkDebt', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    -- Fetch Player's Debt
    MySQL.Async.fetchAll(
        'SELECT IFNULL(SUM(total_debt), 0) AS totalDebt, IFNULL(SUM(amount_paid), 0) AS paidDebt FROM player_loans WHERE citizenid = ?',
        { citizenid },
        function(result)
            if result and #result > 0 then
                local totalDebt = tonumber(result[1].totalDebt) or 0
                local paidDebt = tonumber(result[1].paidDebt) or 0
                local remainingDebt = totalDebt - paidDebt

                -- ✅ Send Data Back to Client
                TriggerClientEvent('bankloan:displayDebitNotification', src, totalDebt, paidDebt)

                -- ✅ Debugging Output
                DebugPrint(string.format("[Check Debt] Player: %s | Total Debt: $%s | Paid: $%s | Remaining: $%s", citizenid, totalDebt, paidDebt, remainingDebt), "info")

            else
                TriggerClientEvent('QBCore:Notify', src, "You have no outstanding loans.", "error")
            end
        end
    )
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        LoadPlayerLoans()
    end
end)

-- ✅ Secure Admin Command: Grant Loan
QBCore.Commands.Add('grantloan', 'Grant a loan to a player', {
    { name = 'id', help = 'Player ID' },
    { name = 'amount', help = 'Loan Amount' },
    { name = 'interest', help = 'Interest Rate (Decimal, e.g., 0.05 for 5%)' }
}, true, function(source, args)
    local adminSrc = source
    local targetId = tonumber(args[1])
    local loanAmount = tonumber(args[2])
    local interestRate = tonumber(args[3])

    if not targetId or not loanAmount or loanAmount <= 0 or not interestRate or interestRate < 0 then
        TriggerClientEvent('QBCore:Notify', adminSrc, "Invalid arguments.", "error")
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', adminSrc, "Player not found.", "error")
        return
    end

    local citizenid = targetPlayer.PlayerData.citizenid
    local totalDebt = loanAmount * (1 + interestRate)

    MySQL.Async.insert('INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, ?)',
        { citizenid, loanAmount, interestRate, totalDebt, 0 }, function(insertId)
            if insertId then
                targetPlayer.Functions.AddMoney('bank', loanAmount, "Admin Granted Loan")
                TriggerClientEvent('QBCore:Notify', targetId, string.format("You received a loan of $%d with %.2f%% interest.", loanAmount, interestRate * 100), "success")
                TriggerClientEvent('QBCore:Notify', adminSrc, string.format("Loan granted to Player ID: %d.", targetId), "success")
            else
                TriggerClientEvent('QBCore:Notify', adminSrc, "Failed to grant loan.", "error")
            end
        end)
end, 'admin')

-- ✅ Secure Command: Pay Loan
RegisterNetEvent('bankloan:payLoan')
AddEventHandler('bankloan:payLoan', function(paymentAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or paymentAmount <= 0 then return end

    local citizenid = Player.PlayerData.citizenid

    MySQL.Async.fetchAll('SELECT id, total_debt, amount_paid FROM player_loans WHERE citizenid = ? AND total_debt > amount_paid ORDER BY id ASC',
        { citizenid },
        function(loans)
            if #loans == 0 then
                TriggerClientEvent('QBCore:Notify', src, "No outstanding loans.", "error")
                return
            end

            local remainingPayment = paymentAmount
            for _, loan in ipairs(loans) do
                if remainingPayment <= 0 then break end
                local outstandingAmount = loan.total_debt - loan.amount_paid
                local paymentForLoan = math.min(remainingPayment, outstandingAmount)
                MySQL.Async.execute('UPDATE player_loans SET amount_paid = amount_paid + ? WHERE id = ?', { paymentForLoan, loan.id })
                remainingPayment = remainingPayment - paymentForLoan
            end

            Player.Functions.RemoveMoney('bank', paymentAmount, "Loan Payment")
            TriggerClientEvent('QBCore:Notify', src, "You paid $" .. paymentAmount .. " towards your loan.", "success")

            MySQL.Async.fetchScalar('SELECT COUNT(*) FROM player_loans WHERE citizenid = ? AND total_debt > amount_paid', { citizenid },
                function(remainingDebts)
                    if remainingDebts == 0 then
                        MySQL.Async.execute('UPDATE players SET credit = credit + 150 WHERE citizenid = ?', { citizenid })
                        TriggerClientEvent('QBCore:Notify', src, "Loan fully repaid! You received 150 credit.", "success")
                    end
                end)
        end)
end)

-- ✅ Secure Commands: Add/Remove Credit & Debt
local function SecureUpdateCreditDebt(command, column, operation, successMessage)
    QBCore.Commands.Add(command, successMessage, {
        { name = 'id', help = 'Player ID' },
        { name = 'amount', help = 'Amount' }
    }, true, function(source, args)
        local targetId = tonumber(args[1])
        local amount = tonumber(args[2])

        if not targetId or not amount or amount <= 0 then
            TriggerClientEvent('QBCore:Notify', source, "Invalid Player ID or amount.", "error")
            return
        end

        local targetPlayer = QBCore.Functions.GetPlayer(targetId)
        if not targetPlayer then
            TriggerClientEvent('QBCore:Notify', source, "Player not found.", "error")
            return
        end

        local citizenid = targetPlayer.PlayerData.citizenid
        local query = string.format('UPDATE players SET %s = GREATEST(0, %s %s ?) WHERE citizenid = ?', column, column, operation)

        MySQL.Async.execute(query, { amount, citizenid })
        TriggerClientEvent('QBCore:Notify', source, successMessage, "success")
    end, 'admin')
end

SecureUpdateCreditDebt('addcredit', 'credit', '+', "Credit added to player.")
SecureUpdateCreditDebt('removecredit', 'credit', '-', "Credit removed from player.")
SecureUpdateCreditDebt('adddebit', 'debit', '+', "Debit added to player.")
SecureUpdateCreditDebt('removedebit', 'debit', '-', "Debit removed from player.")

-- Check for updates
local CurrentVersion = "Qv1.0.7"
local RepoURL = "https://api.github.com/repos/Bert5580/Bank_Loans/releases/latest"

function CheckForUpdates()
    PerformHttpRequest(RepoURL, function(statusCode, response)
        if statusCode == 200 and response then
            local LatestVersion = response:match('"tag_name":"(.-)"')
            if LatestVersion and LatestVersion ~= CurrentVersion then
                print(string.format(
                    "[Bank Loans]: \27[33mA new version is available! (Current: %s, Latest: %s)\27[0m",
                    CurrentVersion, LatestVersion
                ))
                print(string.format(
                    "[Bank Loans]: Download at: \27[31mhttps://github.com/Bert5580/Bank_Loans/releases/tag/%s\27[0m",
                    LatestVersion
                ))
            else
                print("[Bank Loans]: You are using the latest version.")
            end
        else
            print("[Bank Loans]: Failed to check for updates.")
        end
    end, "GET", "", { ["User-Agent"] = "Mozilla/5.0" })
end

RegisterNetEvent('bankloan:getCreditAndLoans')
AddEventHandler('bankloan:getCreditAndLoans', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        print("[DEBUG] ERROR: Player not found.")
        return 
    end

    print("[DEBUG] Server Received Loan Request from: " .. src)

    local citizenid = Player.PlayerData.citizenid
    MySQL.Async.fetchScalar('SELECT IFNULL(credit, 0) FROM players WHERE citizenid = ?', { citizenid }, function(credit)
        MySQL.Async.fetchAll('SELECT * FROM player_loans WHERE citizenid = ?', { citizenid }, function(loans)
            print("[DEBUG] Sending Loan Menu to Client. Credit: $" .. credit)
            TriggerClientEvent('bankloan:openLoanMenu', src, credit, loans)
        end)
    end)
end)

RegisterNetEvent('bankloan:giveLoan')
AddEventHandler('bankloan:giveLoan', function(loanAmount, interestRate, requiredCredit)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    -- Fetch player's credit score
    MySQL.Async.fetchScalar('SELECT IFNULL(credit, 0) FROM players WHERE citizenid = ?', { citizenid }, function(credit)
        if credit < requiredCredit then
            TriggerClientEvent('QBCore:Notify', src, "You don't have enough credit for this loan.", "error")
            return
        end

        -- Deduct required credit
        local newCredit = credit - requiredCredit
        MySQL.Async.execute('UPDATE players SET credit = ? WHERE citizenid = ?', { newCredit, citizenid })

        local totalDebt = loanAmount * (1 + interestRate)
        
        -- Insert loan into database
        MySQL.Async.insert(
            'INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, ?)',
            { citizenid, loanAmount, interestRate, totalDebt, 0 },
            function(insertId)
                if insertId then
                    -- ✅ Give the player money
                    Player.Functions.AddMoney('bank', loanAmount, "Loan Granted")

                    -- ✅ Notify the player
                    TriggerClientEvent('QBCore:Notify', src, "Loan granted! Amount: $" .. loanAmount, "success")

                    -- ✅ Debugging Output
                    DebugPrint(string.format("[Loan Granted] Player: %s | Amount: $%d | Interest: %.2f%% | New Credit: %d", citizenid, loanAmount, interestRate * 100, newCredit), "info")
                else
                    TriggerClientEvent('QBCore:Notify', src, "Loan processing failed.", "error")
                end
            end
        )
    end)
end)
