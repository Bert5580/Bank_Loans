local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

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

    MySQL.Async.fetchAll("SHOW COLUMNS FROM users LIKE 'credit_score'", {}, function(result)
        if #result == 0 then
            DebugPrint("[ERROR] Column 'credit_score' does not exist in the 'users' table.", "error")
        else
            DebugPrint("[INFO] Column 'credit_score' exists in the 'users' table.", "info")
        end
    end)
end

-- Load player loans into memory
local function LoadPlayerLoans()
    MySQL.Async.fetchAll(
        'SELECT identifier, SUM(total_debt) AS totalDebt, SUM(amount_paid) AS paidDebt FROM player_loans GROUP BY identifier',
        {},
        function(results)
            for _, row in ipairs(results) do
                playerLoans[row.identifier] = {
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
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()

    MySQL.Async.fetchScalar('SELECT credit_score FROM users WHERE identifier = ?', { identifier }, function(credit)
        if not credit then credit = 0 end

        MySQL.Async.fetchAll('SELECT * FROM player_loans WHERE identifier = ?', { identifier }, function(loans)
            TriggerClientEvent('bankloan:openLoanMenu', src, credit, loans)
            DebugPrint(string.format("Sent loan menu data to Player ID %s with Credit: %d", src, credit))
        end)
    end)
end)

-- Grant a loan to the player
RegisterNetEvent('bankloan:giveLoan')
AddEventHandler('bankloan:giveLoan', function(loanAmount, interestRate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    loanAmount = loanAmount or 0 -- Default loan amount to 0 if nil
    interestRate = interestRate or 0.05 -- Default interest rate to 5% if nil

    local identifier = xPlayer.getIdentifier()
    local totalDebt = loanAmount * (1 + interestRate)

    MySQL.Async.insert(
        'INSERT INTO player_loans (identifier, loan_amount, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, ?)',
        { identifier, loanAmount, interestRate, totalDebt, 0 },
        function(insertId)
            if insertId then
                xPlayer.addAccountMoney('bank', loanAmount)
                TriggerClientEvent('esx:showNotification', src, "Loan granted! Amount: $" .. loanAmount)
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
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local totalDebt = playerLoans[identifier] and playerLoans[identifier].totalDebt or 0
    local paidDebt = playerLoans[identifier] and playerLoans[identifier].paidDebt or 0

    TriggerClientEvent('bankloan:displayDebitNotification', src, totalDebt, paidDebt)
    DebugPrint(string.format("Debt check for Player ID %s. Total Debt: %.2f, Paid Debt: %.2f", src, totalDebt, paidDebt), "info")
end)

-- Deduct paycheck for loan repayment
RegisterNetEvent('bankloan:paycheckDeduction')
AddEventHandler('bankloan:paycheckDeduction', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local loanData = playerLoans[identifier]

    if not loanData or loanData.totalDebt <= loanData.paidDebt then
        DebugPrint("No outstanding loans for paycheck deduction.", "info")
        return
    end

    local paycheckAmount = xPlayer.getSalary() or 0
    local deduction = math.min(paycheckAmount * Config.PaybackPercentage, loanData.totalDebt - loanData.paidDebt)

    if deduction > 0 then
        playerLoans[identifier].paidDebt = loanData.paidDebt + deduction

        MySQL.Async.execute('UPDATE player_loans SET amount_paid = amount_paid + ? WHERE identifier = ?', { deduction, identifier })
        TriggerClientEvent('esx:showNotification', src, string.format("$%.2f deducted from your paycheck for loan repayment.", deduction))
        DebugPrint(string.format("Paycheck deduction applied for Player ID %s. Deduction: %.2f", src, deduction), "info")
    end
end)

-- Admin command to clear player debt
ESX.RegisterCommand('remove_debit', 'admin', function(xPlayer, args)
    local targetId = tonumber(args.playerId)
    if not targetId then
        TriggerClientEvent('esx:showNotification', xPlayer.source, "Invalid Player ID")
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', xPlayer.source, "Player not found")
        return
    end

    local identifier = targetPlayer.getIdentifier()
    MySQL.Async.execute('DELETE FROM player_loans WHERE identifier = ?', { identifier })

    playerLoans[identifier] = nil

    TriggerClientEvent('esx:showNotification', targetPlayer.source, "Your debt has been cleared.")
    TriggerClientEvent('esx:showNotification', xPlayer.source, "You have cleared the debt for Player ID: " .. targetId)
    DebugPrint(string.format("Debt cleared for Player ID %s.", targetId), "info")
end, false, {
    help = 'Remove all debt for a player',
    arguments = { { name = 'playerId', help = 'Player ID', type = 'number' } }
})
