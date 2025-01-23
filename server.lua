local QBCore = exports['qb-core']:GetCoreObject()

-- Register Loan Event
RegisterNetEvent('bankloan:giveLoan')
AddEventHandler('bankloan:giveLoan', function(loanAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        -- Debug: Log the loan amount received
        print(string.format("Debug: Player ID %d requested loan amount: %s", src, loanAmount))

        -- Find the correct interest rate for the given loan amount
        local interestRate = nil
        for _, loanOption in pairs(Config.LoanOptions) do
            if loanOption.amount == loanAmount then
                interestRate = loanOption.interestRate
                break
            end
        end

        if not interestRate then
            print(string.format("Error: Invalid loan amount requested by Player ID %d", src))
            TriggerClientEvent('QBCore:Notify', src, "Invalid loan amount. Please select a valid option.", "error")
            return
        end

        -- Calculate the total debt
        local totalDebt = loanAmount + (loanAmount * interestRate)

        -- Insert the loan into the database
        MySQL.Async.execute('INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) VALUES (@citizenid, @loan_amount, @interest_rate, @total_debt, @amount_paid)', {
            ['@citizenid'] = Player.PlayerData.citizenid,
            ['@loan_amount'] = loanAmount,
            ['@interest_rate'] = interestRate,
            ['@total_debt'] = totalDebt,
            ['@amount_paid'] = 0
        })

        -- Add the loan amount to the player's wallet
        Player.Functions.AddMoney('cash', loanAmount)

        -- Notify the player
        TriggerClientEvent('QBCore:Notify', src, string.format("You received a loan of %s%s with %s%% interest.", Config.CurrencySymbol, loanAmount, interestRate * 100), "success")
    else
        print("Error: Player not found while processing loan.")
    end
end)

-- Register Command to Check Debt
RegisterNetEvent('bankloan:checkDebt')
AddEventHandler('bankloan:checkDebt', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        MySQL.Async.fetchScalar('SELECT SUM(total_debt - amount_paid) AS remaining_debt FROM player_loans WHERE citizenid = @citizenid', {
            ['@citizenid'] = Player.PlayerData.citizenid
        }, function(remainingDebt)
            remainingDebt = tonumber(remainingDebt) or 0
            TriggerClientEvent('bankloan:displayDebitNotification', src, remainingDebt)
        end)
    else
        print("Error: Player not found while checking debt.")
    end
end)

-- Remove Debt Command for Admins
QBCore.Commands.Add('remove_debit', 'Clear all debt for a player (Admin Only)', {{name = 'id', help = 'Player ID'}}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])

    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, "Invalid Player ID", "error")
        return
    end

    local Player = QBCore.Functions.GetPlayer(targetId)
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, "Player not found", "error")
        return
    end

    -- Clear debt from the database
    MySQL.Async.execute('DELETE FROM player_loans WHERE citizenid = @citizenid', {
        ['@citizenid'] = Player.PlayerData.citizenid
    })

    TriggerClientEvent('QBCore:Notify', targetId, "Your debt has been cleared.", "success")
    TriggerClientEvent('QBCore:Notify', src, "You have cleared the debt for Player ID: " .. targetId, "success")
end, 'admin')

-- Persist Data on Player Drop
AddEventHandler('playerDropped', function()
    local src = source
    -- Handle data persistence if necessary
end)

-- Debugging: Log Server Start
if Config.Debug then
    print("Debug: Server script loaded successfully.")
end
