local QBCore = exports['qb-core']:GetCoreObject()

-- Debug print helper function
function DebugPrint(message)
    if Config.Debug then
        local timestamp = math.floor(GetGameTimer() / 1000) -- Time in seconds
        print(string.format("[%d] Debug: %s", timestamp, message))
    end
end

Citizen.CreateThread(function()
    DebugPrint("Loan client script initialized.")
    DebugPrint("Loan Locations - " .. json.encode(Config.LoanLocations))

    AddLoanBlips() -- Add blips for loan locations
    SpawnLoanNPCs() -- Spawn NPCs at all loan locations

    while true do
        local sleep = 1000 -- Default sleep time for optimization
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, coord in pairs(Config.LoanLocations) do
            local distance = #(playerCoords - coord)

            DebugPrint(string.format("Distance to loan location: %.2f", distance))

            if distance < 10.0 then
                sleep = 0 -- Reduce sleep time for smooth rendering

                -- Draw a green dollar sign marker at the loan location
                DrawMarker(29, coord.x, coord.y, coord.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.5, 0, 255, 0, 100, false, true, 2, nil, nil, false)

                if distance < 2.0 then
                    -- Draw text when the player is close enough
                    DrawText3D(coord.x, coord.y, coord.z, Locales['en'] and Locales['en']['press_h'] or 'Press H To Get A Loan')

                    if IsControlJustPressed(0, 74) then -- H key
                        DebugPrint(string.format("Player pressed H near loan location: %.2f, %.2f, %.2f", coord.x, coord.y, coord.z))
                        TriggerEvent('bankloan:openLoanMenu') -- Trigger the qb-menu event
                    end
                end
            end
        end

        Wait(sleep) -- Prevent high CPU usage
    end
end)

RegisterNetEvent('bankloan:openLoanMenu')
AddEventHandler('bankloan:openLoanMenu', function()
    DebugPrint("Opening loan menu")

    local loanOptions = {}

    for _, option in ipairs(Config.LoanOptions) do
        table.insert(loanOptions, {
            header = string.format("%s%s (Interest: %s%%)", Config.CurrencySymbol, option.amount, option.interestRate * 100),
            params = {
                event = 'bankloan:confirmLoan',
                args = option
            }
        })
    end

    table.insert(loanOptions, {
        header = "Close Menu",
        params = { event = '' }
    })

    exports['qb-menu']:openMenu(loanOptions)
end)

RegisterNetEvent('bankloan:confirmLoan')
AddEventHandler('bankloan:confirmLoan', function(option)
    QBCore.Functions.Notify(string.format("You selected a loan of %s%s with %s%% interest.", Config.CurrencySymbol, option.amount, option.interestRate * 100), "success")

    local debtRemaining = option.amount + (option.amount * option.interestRate)

    DebugPrint(string.format("Loan confirmed with amount: %s%s, interest rate: %.2f%%, total debt: %s%s", Config.CurrencySymbol, option.amount, option.interestRate * 100, Config.CurrencySymbol, debtRemaining))

    TriggerServerEvent('bankloan:giveLoan', debtRemaining)
end)

RegisterNetEvent('bankloan:showDebit')
AddEventHandler('bankloan:showDebit', function(debt)
    if debt > 0 then
        QBCore.Functions.Notify(string.format("Your remaining debt is %s%s.", Config.CurrencySymbol, debt), "primary")
    else
        QBCore.Functions.Notify("You have no remaining debt.", "success")
    end
end)

RegisterCommand('debit', function()
    TriggerServerEvent('bankloan:checkDebt') -- Trigger the server to fetch debt
end)

RegisterNetEvent('bankloan:displayDebitNotification')
AddEventHandler('bankloan:displayDebitNotification', function(totalDebt, paidDebt)
    local remainingDebt = totalDebt - paidDebt

    if remainingDebt > 0 then
        QBCore.Functions.Notify(string.format("You have %s%s of %s%s left to pay on your loan.", Config.CurrencySymbol, remainingDebt, Config.CurrencySymbol, totalDebt), "error")
    else
        QBCore.Functions.Notify("Congratulations! You have fully repaid your loan.", "success")
    end
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.75, 0.75) -- Increased size for better visibility
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

function AddLoanBlips()
    for _, coord in pairs(Config.LoanLocations) do
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
        SetBlipSprite(blip, 108) -- Dollar sign icon
        SetBlipScale(blip, 1.0) -- Blip size
        SetBlipColour(blip, 2) -- Green color
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bank Loan") -- Blip name
        EndTextCommandSetBlipName(blip)

        DebugPrint(string.format("Blip added at x=%.2f, y=%.2f, z=%.2f", coord.x, coord.y, coord.z))
    end
end

function SpawnLoanNPCs()
    local npcLocations = Config.NPCSpawnLocations
    local npcModel = Config.NPCModel

    DebugPrint("Starting NPC spawn process.")
    DebugPrint("NPC Model Hash: " .. tostring(npcModel))

    -- Request and load the NPC model
    RequestModel(npcModel)
    local attempts = 0
    while not HasModelLoaded(npcModel) do
        Wait(10)
        attempts = attempts + 1
        if attempts > 500 then -- Timeout after 5 seconds
            DebugPrint("Error: NPC model failed to load after multiple attempts.")
            return
        end
    end

    DebugPrint("NPC model loaded successfully.")

    -- Spawn NPCs at all configured locations
    for _, location in pairs(npcLocations) do
        local npc = CreatePed(4, npcModel, location.x, location.y, location.z - 1.0, location.w, false, true)
        if npc and DoesEntityExist(npc) then
            SetEntityInvincible(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            FreezeEntityPosition(npc, true)
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, true)

            DebugPrint(string.format("NPC spawned at location: x=%.2f, y=%.2f, z=%.2f, heading=%.2f", location.x, location.y, location.z, location.w))
        else
            DebugPrint(string.format("Error: Failed to spawn NPC at location: x=%.2f, y=%.2f, z=%.2f, heading=%.2f", location.x, location.y, location.z, location.w))
        end
    end

    -- Clean up the model to save memory
    SetModelAsNoLongerNeeded(npcModel)
end

DebugPrint("All client scripts loaded successfully")
