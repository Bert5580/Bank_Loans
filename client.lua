local QBCore = exports['qb-core']:GetCoreObject()

-- Debug print helper function
local function DebugPrint(message, level)
    if Config.Debug then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local levels = { info = "[INFO]", warning = "[WARNING]", error = "[ERROR]" }
        local logLevel = levels[level] or "[INFO]"
        print(string.format("[%s] %s %s", timestamp, logLevel, message))
    end
end

-- Add loan blips to the map
local function AddLoanBlips()
    for _, coord in pairs(Config.LoanLocations) do
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
        SetBlipSprite(blip, 108)
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bank Loans")
        EndTextCommandSetBlipName(blip)
    end
end

-- Spawn loan NPCs
local function SpawnLoanNPCs()
    RequestModel(Config.NPCModel)
    while not HasModelLoaded(Config.NPCModel) do Wait(10) end

    for _, location in pairs(Config.NPCSpawnLocations) do
        local npc = CreatePed(4, Config.NPCModel, location.x, location.y, location.z - 1.0, location.w, false, true)
        if npc and DoesEntityExist(npc) then
            SetEntityInvincible(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            FreezeEntityPosition(npc, true)
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, true)
        end
    end

    SetModelAsNoLongerNeeded(Config.NPCModel)
end

-- Display loan prompt when near NPC
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearNPC = false

        for _, npc in pairs(Config.NPCSpawnLocations) do
            if #(playerCoords - vector3(npc.x, npc.y, npc.z)) < 2.0 then
                nearNPC = true
                QBCore.Functions.DrawText3D(npc.x, npc.y, npc.z + 1.0, "[H] To Get A Loan")

                if IsControlJustReleased(0, 74) then  -- 74 = H key
                    TriggerServerEvent('bankloan:getCreditAndLoans')
                end
            end
        end

        if not nearNPC then Wait(1000) else Wait(0) end
    end
end)

-- Pay Loan via Command
RegisterCommand('pay_loan', function(_, args)
    local paymentAmount = tonumber(args[1]) or 0
    if paymentAmount > 0 then
        TriggerServerEvent('bankloan:payLoan', paymentAmount)
    else
        QBCore.Functions.Notify("Invalid payment amount.", "error")
    end
end, false)

RegisterCommand('check_debit', function()
    TriggerServerEvent('bankloan:checkDebt')
end, false)

-- Open Loan Menu using qb-menu
RegisterNetEvent('bankloan:openLoanMenu', function(credit, loans)
    local menuItems = {
        {
            header = "Available Credit: " .. credit,
            isMenuHeader = true
        }
    }

    for _, loanOption in ipairs(Config.LoanOptions) do
        table.insert(menuItems, {
            header = "$" .. loanOption.amount .. " Loan",
            txt = "Interest: " .. (loanOption.interestRate * 100) .. "% | Required Credit: " .. loanOption.requiredCredit,
            params = {
                event = "bankloan:requestLoan",
                args = {
                    amount = loanOption.amount,
                    interestRate = loanOption.interestRate,
                    requiredCredit = loanOption.requiredCredit
                }
            }
        })
    end

    exports['qb-menu']:openMenu(menuItems)
end)

-- Event to Request Loan
RegisterNetEvent('bankloan:requestLoan', function(data)
    TriggerServerEvent('bankloan:giveLoan', data.amount, data.interestRate, data.requiredCredit)
end)

-- Display Debt Notification
RegisterNetEvent('bankloan:displayDebitNotification', function(totalDebt, paidDebt)
    local remainingDebt = totalDebt - paidDebt
    QBCore.Functions.Notify(string.format("Total Debt: $%.2f | Paid: $%.2f | Remaining: $%.2f", totalDebt, paidDebt, remainingDebt), "primary")
end)

-- Initialize blips and NPCs on resource start
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        AddLoanBlips()
        SpawnLoanNPCs()
    end
end)
