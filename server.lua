local QBCore = exports['qb-core']:GetCoreObject()
local loans = {} -- Store player loans

-- Configuration
Config = {
    Debug = false, -- Enable or disable debug messages
    CurrencySymbol = "$" -- Symbol used for monetary values
}

-- Helper function for debug logs
local function DebugLog(message)
    if Config.Debug then
        print(message)
    end
end

DebugLog("Debug: QB-Core server script started loading")

RegisterNetEvent('bankloan:giveLoan')
AddEventHandler('bankloan:giveLoan', function(loanAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        -- Check if the player already has an outstanding loan
        if loans[src] and loans[src] > 0 then
            TriggerClientEvent('QBCore:Notify', src, "You already have an outstanding loan. Pay it back first!", "error")
            return
        end

        -- Add cash to the player's wallet
        Player.Functions.AddMoney('cash', loanAmount)

        -- Update the player's debit in the database
        MySQL.Async.execute('UPDATE players SET debit = debit + @amount WHERE citizenid = @citizenid', {
            ['@amount'] = loanAmount,
            ['@citizenid'] = Player.PlayerData.citizenid
        })

        -- Store in runtime loans table
        loans[src] = loanAmount

        TriggerClientEvent('QBCore:Notify', src, string.format("You received a loan of %s%s. Don't forget to pay it back!", Config.CurrencySymbol, loanAmount), "success")
        DebugLog(string.format("Debug: Player ID %s received a loan of %s%s.", src, Config.CurrencySymbol, loanAmount))
    else
        DebugLog("Error: Player not found while processing loan.")
    end
end)

RegisterNetEvent('bankloan:checkDebt')
AddEventHandler('bankloan:checkDebt', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        MySQL.Async.fetchScalar('SELECT debit FROM players WHERE citizenid = @citizenid', {
            ['@citizenid'] = Player.PlayerData.citizenid
        }, function(debit)
            if debit and tonumber(debit) > 0 then
                TriggerClientEvent('bankloan:displayDebitNotification', src, tonumber(debit))
            else
                TriggerClientEvent('bankloan:displayDebitNotification', src, 0)
            end
        end)
    else
        DebugLog("Error: Player not found while checking debt.")
    end
end)

QBCore.Commands.Add('remove_debit', 'Remove all debt for a player (Admin Only)', {{name = 'id', help = 'Player ID'}}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1]) -- Get the target player's ID

    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, "Invalid Player ID", "error")
        DebugLog("Debug: Invalid Player ID provided for remove_debit command")
        return
    end

    local Player = QBCore.Functions.GetPlayer(targetId)
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, "Player not found", "error")
        DebugLog("Debug: Player not found for remove_debit command, Player ID: " .. targetId)
        return
    end

    -- Reset the player's debt
    loans[targetId] = nil
    MySQL.Async.execute('UPDATE players SET debit = 0 WHERE citizenid = @citizenid', {
        ['@citizenid'] = Player.PlayerData.citizenid
    })

    TriggerClientEvent('QBCore:Notify', targetId, "Your debt has been cleared.", "success")
    TriggerClientEvent('QBCore:Notify', src, "You have cleared the debt for Player ID: " .. targetId, "success")

    DebugLog(string.format("Debug: Admin (ID: %d) cleared debt for Player ID: %d", src, targetId))
end, 'admin') -- Only allow admins to execute this command

AddEventHandler('playerDropped', function(reason)
    local src = source

    if loans[src] and loans[src] > 0 then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            MySQL.Async.execute('UPDATE players SET debit = @debt WHERE citizenid = @citizenid', {
                ['@debt'] = loans[src],
                ['@citizenid'] = Player.PlayerData.citizenid
            })
        end

        DebugLog(string.format("Debug: Player %d disconnected with outstanding loan of %s%d", src, Config.CurrencySymbol, loans[src]))
    end

    loans[src] = nil -- Remove the player from the loans table
end)

DebugLog("Debug: QB-Core server script loaded successfully")
