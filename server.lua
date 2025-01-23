local QBCore = exports['qb-core']:GetCoreObject()

-- Debug print helper function
local function DebugPrint(message)
    if Config.Debug then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        print(string.format("[%s] Debug: %s", timestamp, message))
    end
end

-- Add loan to the player
RegisterNetEvent('bankloan:giveLoan', function(loanAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        local citizenid = Player.PlayerData.citizenid
        local interestRate = Config.LoanInterestRate
        local totalDebt = loanAmount + (loanAmount * interestRate)

        -- Insert loan details into the database
        MySQL.Async.execute(
            [[
                INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid)
                VALUES (@citizenid, @loan_amount, @interest_rate, @total_debt, 0)
            ]],
            {
                ['@citizenid'] = citizenid,
                ['@loan_amount'] = loanAmount,
                ['@interest_rate'] = interestRate,
                ['@total_debt'] = totalDebt
            },
            function(rowsChanged)
                if rowsChanged > 0 then
                    -- Add money to the player's wallet
                    Player.Functions.AddMoney('cash', loanAmount)
                    TriggerClientEvent('QBCore:Notify', src, string.format("You have received a loan of %s%s.", Config.CurrencySymbol, loanAmount), "success")
                    DebugPrint(string.format("Loan granted: CitizenID=%s, Amount=%s%s, Total Debt=%s%s", citizenid, Config.CurrencySymbol, loanAmount, Config.CurrencySymbol, totalDebt))
                else
                    TriggerClientEvent('QBCore:Notify', src, "An error occurred while processing your loan.", "error")
                    DebugPrint(string.format("Failed to grant loan for CitizenID=%s", citizenid))
                end
            end
        )
    else
        DebugPrint("Error: Player not found.")
    end
end)

-- Check player debt
RegisterNetEvent('bankloan:checkDebt', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        local citizenid = Player.PlayerData.citizenid

        MySQL.Async.fetchAll(
            [[
                SELECT total_debt, amount_paid 
                FROM player_loans 
                WHERE citizenid = @citizenid
            ]],
            {
                ['@citizenid'] = citizenid
            },
            function(results)
                if results and #results > 0 then
                    local totalDebt = results[1].total_debt
                    local amountPaid = results[1].amount_paid
                    TriggerClientEvent('bankloan:displayDebitNotification', src, totalDebt, amountPaid)
                    DebugPrint(string.format("Debt check: CitizenID=%s, Total Debt=%s%s, Amount Paid=%s%s", citizenid, Config.CurrencySymbol, totalDebt, Config.CurrencySymbol, amountPaid))
                else
                    TriggerClientEvent('bankloan:displayDebitNotification', src, 0, 0)
                    DebugPrint(string.format("No debt found for CitizenID=%s", citizenid))
                end
            end
        )
    else
        DebugPrint("Error: Player not found for debt check.")
    end
end)

-- Remove player debt (Admin Command)
RegisterCommand('remove_debit', function(source, args)
    local src = source
    local targetId = tonumber(args[1])

    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, "Invalid Player ID", "error")
        DebugPrint("Invalid Player ID provided for remove_debit command")
        return
    end

    local Player = QBCore.Functions.GetPlayer(targetId)
    if Player then
        local citizenid = Player.PlayerData.citizenid

        MySQL.Async.execute(
            [[
                DELETE FROM player_loans 
                WHERE citizenid = @citizenid
            ]],
            {
                ['@citizenid'] = citizenid
            },
            function(rowsChanged)
                if rowsChanged > 0 then
                    TriggerClientEvent('QBCore:Notify', targetId, "Your debt has been cleared.", "success")
                    TriggerClientEvent('QBCore:Notify', src, string.format("You have cleared the debt for Player ID: %d", targetId), "success")
                    DebugPrint(string.format("Debt cleared for CitizenID=%s by Admin ID=%d", citizenid, src))
                else
                    TriggerClientEvent('QBCore:Notify', src, "Failed to clear debt for the player.", "error")
                    DebugPrint(string.format("Failed to clear debt for CitizenID=%s", citizenid))
                end
            end
        )
    else
        TriggerClientEvent('QBCore:Notify', src, "Player not found", "error")
        DebugPrint(string.format("Player not found for remove_debit command, Player ID=%d", targetId))
    end
end, false) -- False means no permission restrictions

-- Debug script initialization
DebugPrint("Server script loaded successfully")
