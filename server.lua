local QBCore = exports['qb-core']:GetCoreObject()

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

-- Pay Loan Event
RegisterNetEvent('bankloan:payLoan')
AddEventHandler('bankloan:payLoan', function(paymentAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    -- Fetch total debt and amount paid
    MySQL.Async.fetchAll(
        'SELECT id, total_debt, amount_paid FROM player_loans WHERE citizenid = ? AND total_debt > amount_paid ORDER BY id ASC',
        { citizenid },
        function(loans)
            if #loans == 0 then
                TriggerClientEvent('QBCore:Notify', src, "You have no outstanding loans.", "error")
                return
            end

            local remainingPayment = paymentAmount
            local allLoansPaidOff = true

            -- Process the payment across loans
            for _, loan in ipairs(loans) do
                if remainingPayment <= 0 then break end

                local outstandingAmount = loan.total_debt - loan.amount_paid
                local paymentForLoan = math.min(remainingPayment, outstandingAmount)

                -- Update the loan in the database
                MySQL.Async.execute(
                    'UPDATE player_loans SET amount_paid = amount_paid + ? WHERE id = ?',
                    { paymentForLoan, loan.id }
                )

                remainingPayment = remainingPayment - paymentForLoan
            end

            -- Deduct money from player bank account
            if paymentAmount > 0 then
                Player.Functions.RemoveMoney('bank', paymentAmount, "Loan Payment")
                TriggerClientEvent('QBCore:Notify', src, "You paid $" .. paymentAmount .. " towards your loan.", "success")
            end

            -- Check if all loans are fully paid
            MySQL.Async.fetchScalar(
                'SELECT COUNT(*) FROM player_loans WHERE citizenid = ? AND total_debt > amount_paid',
                { citizenid },
                function(remainingDebts)
                    if remainingDebts == 0 then
                        -- All debts are fully paid, reward the player with 150 credit
                        MySQL.Async.fetchScalar('SELECT IFNULL(credit, 0) FROM players WHERE citizenid = ?', { citizenid }, function(currentCredit)
                            local newCredit = currentCredit + 150
                            MySQL.Async.execute('UPDATE players SET credit = ? WHERE citizenid = ?', { newCredit, citizenid })
                            TriggerClientEvent('QBCore:Notify', src, "Congratulations! You have fully paid your loans and received 150 credit.", "success")
                        end)
                    end
                end
            )
        end
    )
end)

QBCore.Commands.Add('grant_loan', 'Grant a loan to a player with a custom interest rate', 
    {
        { name = 'id', help = 'Player ID' },
        { name = 'amount', help = 'Loan Amount' },
        { name = 'interest', help = 'Interest Rate (Decimal, e.g., 0.05 for 5%)' }
    }, 
    true, 
    function(source, args)
        local adminSrc = source
        local targetId = tonumber(args[1])
        local loanAmount = tonumber(args[2])
        local interestRate = tonumber(args[3])

        if not targetId or not loanAmount or loanAmount <= 0 or not interestRate or interestRate < 0 then
            TriggerClientEvent('QBCore:Notify', adminSrc, "Invalid Player ID, loan amount, or interest rate.", "error")
            return
        end

        local targetPlayer = QBCore.Functions.GetPlayer(targetId)
        if not targetPlayer then
            TriggerClientEvent('QBCore:Notify', adminSrc, "Player not found.", "error")
            return
        end

        local citizenid = targetPlayer.PlayerData.citizenid
        local totalDebt = loanAmount * (1 + interestRate)

        -- Insert loan into the database
        MySQL.Async.insert(
            'INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, ?)',
            { citizenid, loanAmount, interestRate, totalDebt, 0 },
            function(insertId)
                if insertId then
                    -- Add loan money to the player's bank account
                    targetPlayer.Functions.AddMoney('bank', loanAmount, "Admin Granted Loan")

                    -- Notify player and admin
                    TriggerClientEvent('QBCore:Notify', targetId, string.format("You received a loan of $%d with %.2f%% interest.", loanAmount, interestRate * 100), "success")
                    TriggerClientEvent('QBCore:Notify', adminSrc, string.format("Loan of $%d granted to Player ID: %d with %.2f%% interest.", loanAmount, targetId, interestRate * 100), "success")
                else
                    TriggerClientEvent('QBCore:Notify', adminSrc, "Failed to grant loan.", "error")
                end
            end
        )
    end, 
    'admin'
)

QBCore.Commands.Add('remove_debit', 'Remove a specific amount of debt from a player', 
    {
        { name = 'id', help = 'Player ID' },
        { name = 'amount', help = 'Amount of debt to remove' }
    }, 
    true, 
    function(source, args)
        local adminSrc = source
        local targetId = tonumber(args[1])
        local removeAmount = tonumber(args[2])

        if not targetId or not removeAmount or removeAmount <= 0 then
            TriggerClientEvent('QBCore:Notify', adminSrc, "Invalid Player ID or amount.", "error")
            return
        end

        local targetPlayer = QBCore.Functions.GetPlayer(targetId)
        if not targetPlayer then
            TriggerClientEvent('QBCore:Notify', adminSrc, "Player not found.", "error")
            return
        end

        local citizenid = targetPlayer.PlayerData.citizenid

        -- Fetch the player's current debt
        MySQL.Async.fetchAll(
            'SELECT IFNULL(SUM(total_debt), 0) AS totalDebt, IFNULL(SUM(amount_paid), 0) AS paidDebt FROM player_loans WHERE citizenid = ?',
            { citizenid },
            function(result)
                if result and #result > 0 then
                    local totalDebt = tonumber(result[1].totalDebt) or 0
                    local paidDebt = tonumber(result[1].paidDebt) or 0
                    local remainingDebt = totalDebt - paidDebt

                    if remainingDebt <= 0 then
                        TriggerClientEvent('QBCore:Notify', adminSrc, "Player has no outstanding debt.", "error")
                        return
                    end

                    local newRemainingDebt = math.max(0, remainingDebt - removeAmount)

                    -- Update the debt in the database
                    MySQL.Async.execute('UPDATE player_loans SET amount_paid = amount_paid + ? WHERE citizenid = ?', { removeAmount, citizenid })

                    -- Notify admin & player
                    TriggerClientEvent('QBCore:Notify', adminSrc, string.format("Removed $%d of debt from Player ID: %d. Remaining Debt: $%d", removeAmount, targetId, newRemainingDebt), "success")
                    TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, string.format("Admin removed $%d of your debt. Remaining: $%d", removeAmount, newRemainingDebt), "primary")

                    -- If debt is fully paid off, grant 150 credit
                    if newRemainingDebt == 0 then
                        MySQL.Async.fetchScalar('SELECT IFNULL(credit, 0) FROM players WHERE citizenid = ?', { citizenid }, function(currentCredit)
                            local newCredit = currentCredit + 150
                            MySQL.Async.execute('UPDATE players SET credit = ? WHERE citizenid = ?', { newCredit, citizenid })
                            TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, "You have fully paid off your debt and received 150 credit!", "success")
                        end)
                    end
                else
                    TriggerClientEvent('QBCore:Notify', adminSrc, "Failed to retrieve player debt.", "error")
                end
            end
        )
    end, 
    'admin'
)

QBCore.Commands.Add('add_debit', 'Add a specific amount of debt to a player', 
    {
        { name = 'id', help = 'Player ID' },
        { name = 'amount', help = 'Amount of debt to add' }
    }, 
    true, 
    function(source, args)
        local adminSrc = source
        local targetId = tonumber(args[1])
        local addAmount = tonumber(args[2])

        if not targetId or not addAmount or addAmount <= 0 then
            TriggerClientEvent('QBCore:Notify', adminSrc, "Invalid Player ID or amount.", "error")
            return
        end

        local targetPlayer = QBCore.Functions.GetPlayer(targetId)
        if not targetPlayer then
            TriggerClientEvent('QBCore:Notify', adminSrc, "Player not found.", "error")
            return
        end

        local citizenid = targetPlayer.PlayerData.citizenid

        -- Add new debt entry to `player_loans` table
        MySQL.Async.insert(
            'INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, ?)',
            { citizenid, addAmount, 0.0, addAmount, 0 },
            function(insertId)
                if insertId then
                    TriggerClientEvent('QBCore:Notify', adminSrc, string.format("Added $%d debt to Player ID: %d", addAmount, targetId), "success")
                    TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, string.format("Admin added $%d to your debt.", addAmount), "primary")
                else
                    TriggerClientEvent('QBCore:Notify', adminSrc, "Failed to add debt.", "error")
                end
            end
        )
    end, 
    'admin'
)

-- Verify database tables and columns
local function VerifyDatabase()
    MySQL.Async.fetchAll("SHOW TABLES LIKE 'player_loans'", {}, function(result)
        if #result == 0 then
            DebugPrint("[ERROR] Table 'player_loans' does not exist in the database.", "error")
        else
            DebugPrint("[INFO] Table 'player_loans' exists in the database.", "info")
        end
    end)

    MySQL.Async.fetchAll("SHOW COLUMNS FROM players LIKE 'credit'", {}, function(result)
        if #result == 0 then
            DebugPrint("[ERROR] Column 'credit' does not exist in the 'players' table.", "error")
        else
            DebugPrint("[INFO] Column 'credit' exists in the 'players' table.", "info")
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
                    "[Bank Loans]: Download it at: \27[31mhttps://github.com/Bert5580/Bank_Loans/releases/tag/%s\27[0m",
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

            -- Send back to client
            TriggerClientEvent('bankloan:displayDebitNotification', src, totalDebt, paidDebt)
        end
    )
end)

-- Admin command to add credit
QBCore.Commands.Add('addcredit', 'Add credit to a player', {{ name = 'id', help = 'Player ID' }, { name = 'amount', help = 'Credit Amount' }}, true, function(source, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not targetId or not amount then
        TriggerClientEvent('QBCore:Notify', source, "Invalid Player ID or amount.", "error")
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, "Player not found.", "error")
        return
    end

    local citizenid = targetPlayer.PlayerData.citizenid
    MySQL.Async.fetchScalar('SELECT IFNULL(credit, 0) FROM players WHERE citizenid = ?', { citizenid }, function(currentCredit)
        local newCredit = currentCredit + amount
        MySQL.Async.execute('UPDATE players SET credit = ? WHERE citizenid = ?', { newCredit, citizenid })
        TriggerClientEvent('QBCore:Notify', source, "Added " .. amount .. " credit to player.", "success")
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, "You received " .. amount .. " credit.", "success")
    end)
end, 'admin')

RegisterNetEvent('bankloan:displayDebitNotification', function(totalDebt, paidDebt)
    local remainingDebt = totalDebt - paidDebt
    QBCore.Functions.Notify(string.format("Total Debt: $%.2f | Paid: $%.2f | Remaining: $%.2f", totalDebt, paidDebt, remainingDebt), "primary")
end)

-- Admin command to remove credit
QBCore.Commands.Add('removecredit', 'Remove credit from a player', {{ name = 'id', help = 'Player ID' }, { name = 'amount', help = 'Credit Amount' }}, true, function(source, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not targetId or not amount then
        TriggerClientEvent('QBCore:Notify', source, "Invalid Player ID or amount.", "error")
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, "Player not found.", "error")
        return
    end

    local citizenid = targetPlayer.PlayerData.citizenid
    MySQL.Async.fetchScalar('SELECT IFNULL(credit, 0) FROM players WHERE citizenid = ?', { citizenid }, function(currentCredit)
        local newCredit = math.max(0, currentCredit - amount)
        MySQL.Async.execute('UPDATE players SET credit = ? WHERE citizenid = ?', { newCredit, citizenid })
        TriggerClientEvent('QBCore:Notify', source, "Removed " .. amount .. " credit from player.", "success")
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, amount .. " credit was removed from your account.", "error")
    end)
end, 'admin')
