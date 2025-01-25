local QBCore = exports['qb-core']:GetCoreObject()

-- Debug print helper function
local function DebugPrint(message)
    if Config.Debug then
        print(string.format("[Debug]: %s", message))
    end
end

-- Main thread for detecting player interaction with loan locations
Citizen.CreateThread(function()
    DebugPrint("Loan client script initialized.")
    DebugPrint("Loan Locations: " .. json.encode(Config.LoanLocations))

    AddLoanBlips() -- Add blips for loan locations
    SpawnLoanNPCs() -- Spawn NPCs at all loan locations

    while true do
        local sleep = 1000 -- Default sleep time for optimization
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, coord in pairs(Config.LoanLocations) do
            local distance = #(playerCoords - coord)

            if distance < 10.0 then
                sleep = 0 -- Reduce sleep for smooth rendering

                -- Draw a marker at the loan location
                DrawMarker(29, coord.x, coord.y, coord.z - 0.9, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.5, 0, 255, 0, 100, false, true, 2, nil, nil, false)

                if distance < 2.0 then
                    -- Draw text for loan interaction
                    DrawText3D(coord.x, coord.y, coord.z, Locales['en'] and Locales['en']['press_h'] or "Press H To Get A Loan")

                    if IsControlJustPressed(0, 74) then -- H key
                        DebugPrint("Player pressed H near loan location.")
                        TriggerServerEvent('bankloan:getCreditAndLoans') -- Request credit and loan info from the server
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Open loan menu using qb-menu
RegisterNetEvent('bankloan:openLoanMenu', function(playerCredit, loans)
    DebugPrint("Opening loan menu for player...")
    if not playerCredit then
        DebugPrint("Error: playerCredit is nil.")
        return
    end

    local loanOptions = {}

    for _, loan in ipairs(Config.LoanOptions) do
        if playerCredit >= (loan.requiredCredit or 0) then
            table.insert(loanOptions, {
                header = string.format("%s%s (Interest: %s%%)", Config.CurrencySymbol, loan.amount, loan.interestRate * 100),
                txt = string.format("Required Credit: %d", loan.requiredCredit or 0),
                params = {
                    event = 'bankloan:confirmLoan',
                    args = loan
                }
            })
        else
            table.insert(loanOptions, {
                header = string.format("%s%s (Interest: %s%%)", Config.CurrencySymbol, loan.amount, loan.interestRate * 100),
                txt = "Insufficient Credit",
                disabled = true
            })
        end
    end

    table.insert(loanOptions, {
        header = "Close Menu",
        params = { event = '' }
    })

    -- Open the menu using qb-menu
    exports['qb-menu']:openMenu(loanOptions)
end)

-- Confirm loan and trigger server event
RegisterNetEvent('bankloan:confirmLoan', function(loan)
    TriggerServerEvent('bankloan:giveLoan', loan.amount, loan.interestRate)
    QBCore.Functions.Notify("Your loan request has been sent.", "success")
end)

-- Display remaining debt to player
RegisterNetEvent('bankloan:showDebit')
AddEventHandler('bankloan:showDebit', function(debt)
    if not debt then
        DebugPrint("Error: Debt data missing for player.")
        return
    end

    if debt > 0 then
        QBCore.Functions.Notify(string.format("Your remaining debt is %s%s.", Config.CurrencySymbol, debt), "primary")
    else
        QBCore.Functions.Notify("You have no remaining debt.", "success")
    end
end)

-- Command to check remaining debt
RegisterCommand('debit', function()
    TriggerServerEvent('bankloan:checkDebt') -- Trigger the server to fetch debt
end)

-- Display debt notification
RegisterNetEvent('bankloan:displayDebitNotification')
AddEventHandler('bankloan:displayDebitNotification', function(totalDebt, paidDebt)
    if not totalDebt or not paidDebt then
        DebugPrint("Error: Missing debt data for notification.")
        return
    end

    local remainingDebt = totalDebt - paidDebt

    if remainingDebt > 0 then
        QBCore.Functions.Notify(string.format("You have %s%s of %s%s left to pay on your loan.", Config.CurrencySymbol, remainingDebt, Config.CurrencySymbol, totalDebt), "error")
    else
        QBCore.Functions.Notify("Congratulations! You have fully repaid your loan.", "success")
    end
end)

-- Helper function to draw 3D text
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Add blips for loan locations
function AddLoanBlips()
    if not Config.LoanLocations or #Config.LoanLocations == 0 then
        DebugPrint("Error: No loan locations configured for blips.")
        return
    end

    for _, coord in pairs(Config.LoanLocations) do
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
        SetBlipSprite(blip, 108) -- Dollar sign icon
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, 2) -- Green
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bank Loans")
        EndTextCommandSetBlipName(blip)
        DebugPrint(string.format("Blip added at x=%.2f, y=%.2f, z=%.2f", coord.x, coord.y, coord.z))
    end
end

-- Spawn loan NPCs
function SpawnLoanNPCs()
    if not Config.NPCSpawnLocations or #Config.NPCSpawnLocations == 0 then
        DebugPrint("Error: No NPC spawn locations configured.")
        return
    end

    local npcModel = Config.NPCModel

    RequestModel(npcModel)
    local attempts = 0
    while not HasModelLoaded(npcModel) do
        Wait(10)
        attempts = attempts + 1
        if attempts > 500 then
            DebugPrint("Error: NPC model failed to load after multiple attempts.")
            return
        end
    end

    DebugPrint("NPC model loaded successfully.")

    for _, location in pairs(Config.NPCSpawnLocations) do
        local npc = CreatePed(4, npcModel, location.x, location.y, location.z - 1.0, location.w, false, true)
        if npc and DoesEntityExist(npc) then
            SetEntityInvincible(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            FreezeEntityPosition(npc, true)
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, true)
            DebugPrint(string.format("NPC spawned at x=%.2f, y=%.2f, z=%.2f, heading=%.2f", location.x, location.y, location.z, location.w))
        else
            DebugPrint(string.format("Error: Failed to spawn NPC at x=%.2f, y=%.2f, z=%.2f, heading=%.2f", location.x, location.y, location.z, location.w))
        end
    end

    SetModelAsNoLongerNeeded(npcModel)
end

DebugPrint("All client scripts loaded successfully.")
