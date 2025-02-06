local QBCore = exports['qb-core']:GetCoreObject()

local playerLoans = {}

-- Debug print helper function
local function DebugPrint(message, level)
    if Config.Debug then
        local timestamp = "[" .. math.floor(GetGameTimer() / 1000) .. "s]"
        local levels = { info = "[INFO]", warning = "[WARNING]", error = "[ERROR]" }
        local logLevel = levels[level] or "[INFO]"
        print(string.format("%s %s %s", timestamp, logLevel, message))
    end
end

-- Verify database structure
local function VerifyDatabase()
    MySQL.Async.fetchAll("SHOW TABLES LIKE 'player_loans'", {}, function(result)
        if #result == 0 then
            DebugPrint("[ERROR] Table 'player_loans' does not exist.", "error")
        else
            DebugPrint("[INFO] Table 'player_loans' found.", "info")
        end
    end)

    MySQL.Async.fetchAll("SHOW COLUMNS FROM players LIKE 'credit'", {}, function(result)
        if #result == 0 then
            DebugPrint("[ERROR] Column 'credit' is missing in 'players' table.", "error")
        else
            DebugPrint("[INFO] Column 'credit' exists in 'players' table.", "info")
        end
    end)
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

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        VerifyDatabase()
        LoadPlayerLoans()
        CheckForUpdates()
    end
end)

-- Check for updates
local CurrentVersion = "Qv1.0.4"
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

-- Get player credit and loans
RegisterNetEvent('bankloan:getCreditAndLoans')
AddEventHandler('bankloan:getCreditAndLoans', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    MySQL.Async.fetchScalar('SELECT IFNULL(credit, 0) FROM players WHERE citizenid = ?', { citizenid }, function(credit)
        MySQL.Async.fetchAll('SELECT * FROM player_loans WHERE citizenid = ?', { citizenid }, function(loans)
            TriggerClientEvent('bankloan:openLoanMenu', src, credit, loans)
        end)
    end)
end)

-- Grant a loan to the player
RegisterNetEvent('bankloan:giveLoan')
AddEventHandler('bankloan:giveLoan', function(loanAmount, interestRate, requiredCredit)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    MySQL.Async.fetchScalar('SELECT IFNULL(credit, 0) FROM players WHERE citizenid = ?', { citizenid }, function(credit)
        if credit < requiredCredit then
            TriggerClientEvent('QBCore:Notify', src, "You don't have enough credit for this loan.", "error")
            return
        end

        local newCredit = credit - requiredCredit
        MySQL.Async.execute('UPDATE players SET credit = ? WHERE citizenid = ?', { newCredit, citizenid })

        local totalDebt = loanAmount * (1 + interestRate)
        MySQL.Async.insert(
            'INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, ?)',
            { citizenid, loanAmount, interestRate, totalDebt, 0 },
            function(insertId)
                if insertId then
                    Player.Functions.AddMoney('bank', loanAmount, "Loan Granted")
                    TriggerClientEvent('QBCore:Notify', src, "Loan granted! Amount: $" .. loanAmount, "success")
                else
                    TriggerClientEvent('QBCore:Notify', src, "Loan processing failed.", "error")
                end
            end
        )
    end)
end)

-- Check player debt
RegisterNetEvent('bankloan:checkDebt')
AddEventHandler('bankloan:checkDebt', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    MySQL.Async.fetchAll(
        'SELECT IFNULL(SUM(total_debt), 0) AS totalDebt, IFNULL(SUM(amount_paid), 0) AS paidDebt FROM player_loans WHERE citizenid = ?',
        { citizenid },
        function(result)
            local totalDebt = tonumber(result[1].totalDebt) or 0
            local paidDebt = tonumber(result[1].paidDebt) or 0
            TriggerClientEvent('bankloan:displayDebitNotification', src, totalDebt, paidDebt)
        end
    )
end)

-- Pay Loan
RegisterNetEvent('bankloan:payLoan')
AddEventHandler('bankloan:payLoan', function(paymentAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    MySQL.Async.fetchAll(
        'SELECT id, total_debt, amount_paid FROM player_loans WHERE citizenid = ? AND total_debt > amount_paid ORDER BY id ASC',
        { citizenid },
        function(loans)
            if #loans == 0 then
                TriggerClientEvent('QBCore:Notify', src, "You have no outstanding loans.", "error")
                return
            end

            local remainingPayment = paymentAmount

            for _, loan in ipairs(loans) do
                if remainingPayment <= 0 then break end
                local outstandingAmount = loan.total_debt - loan.amount_paid
                local paymentForLoan = math.min(remainingPayment, outstandingAmount)

                MySQL.Async.execute(
                    'UPDATE player_loans SET amount_paid = amount_paid + ? WHERE id = ?',
                    { paymentForLoan, loan.id }
                )

                remainingPayment = remainingPayment - paymentForLoan
            end

            Player.Functions.RemoveMoney('bank', paymentAmount, "Loan Payment")
            TriggerClientEvent('QBCore:Notify', src, "You paid $" .. paymentAmount .. " towards your loan.", "success")
        end
    )
end)
