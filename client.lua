local QBCore = exports['qb-core']:GetCoreObject()

-- Debug print function
local function DebugPrint(message, level)
    if Config.Debug then
        local timestamp = "[" .. math.floor(GetGameTimer() / 1000) .. "s]" -- Fixes `os.date()` issue
        local levels = { info = "[INFO]", warning = "[WARNING]", error = "[ERROR]" }
        local logLevel = levels[level] or "[INFO]"
        print(string.format("%s %s %s", timestamp, logLevel, message))
    end
end

-- Add NPCs using qb-target
local function SetupLoanNPCs()
    RequestModel(Config.NPCModel)
    while not HasModelLoaded(Config.NPCModel) do Wait(10) end

    for _, npc in ipairs(Config.NPCSpawnLocations) do
        local npcEntity = CreatePed(4, Config.NPCModel, npc.x, npc.y, npc.z - 1.0, npc.w, false, true)
        SetEntityInvincible(npcEntity, true)
        SetBlockingOfNonTemporaryEvents(npcEntity, true)
        FreezeEntityPosition(npcEntity, true)
        TaskStartScenarioInPlace(npcEntity, "WORLD_HUMAN_CLIPBOARD", 0, true)

        exports['qb-target']:AddTargetEntity(npcEntity, {
            options = {
                {
                    type = "client",
                    event = "bankloan:openLoanMenu",
                    icon = "fas fa-dollar-sign",
                    label = "Get a Loan"
                }
            },
            distance = 2.5
        })

        DebugPrint("NPC spawned at: x=" .. npc.x .. ", y=" .. npc.y .. ", z=" .. npc.z, "info")
    end

    SetModelAsNoLongerNeeded(Config.NPCModel)
end

-- Add Loan Blips
local function AddLoanBlips()
    for _, coord in ipairs(Config.LoanLocations) do
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

-- Open loan menu
RegisterNetEvent('bankloan:openLoanMenu', function(credit, loans)
    local menu = {
        {
            header = "Bank Loans - Available Credit: $" .. credit,
            isMenuHeader = true
        }
    }

    for _, loan in ipairs(Config.LoanOptions) do
        table.insert(menu, {
            header = "$" .. loan.amount .. " Loan",
            txt = "Interest: " .. (loan.interestRate * 100) .. "% | Required Credit: " .. loan.requiredCredit,
            params = {
                event = "bankloan:requestLoan",
                args = {
                    amount = loan.amount,
                    interestRate = loan.interestRate,
                    requiredCredit = loan.requiredCredit
                }
            }
        })
    end

    exports['qb-menu']:openMenu(menu)
end)

-- Request Loan
RegisterNetEvent('bankloan:requestLoan', function(data)
    TriggerServerEvent('bankloan:giveLoan', data.amount, data.interestRate, data.requiredCredit)
end)

-- Display debt notification
RegisterNetEvent('bankloan:displayDebitNotification', function(totalDebt, paidDebt)
    local remainingDebt = totalDebt - paidDebt
    QBCore.Functions.Notify(string.format("Total Debt: $%.2f | Paid: $%.2f | Remaining: $%.2f", totalDebt, paidDebt, remainingDebt), "primary")
end)

-- Display credit info
RegisterNetEvent('bankloan:displayCreditInfo', function(credit)
    QBCore.Functions.Notify("Your current credit: " .. credit, "primary")
end)

-- Check debt command
RegisterCommand('check_debit', function()
    TriggerServerEvent('bankloan:checkDebt')
end, false)

-- Pay Loan
RegisterCommand('pay_loan', function(_, args)
    local paymentAmount = tonumber(args[1]) or 0
    if paymentAmount > 0 then
        TriggerServerEvent('bankloan:payLoan', paymentAmount)
    else
        QBCore.Functions.Notify("Invalid payment amount.", "error")
    end
end, false)

-- Setup NPCs and blips on resource start
AddEventHandler('onClientResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        SetupLoanNPCs()
        AddLoanBlips()
    end
end)

-- Interaction prompt for those who do not use qb-target
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local isNearNPC = false

        for _, npc in ipairs(Config.NPCSpawnLocations) do
            if #(playerCoords - vector3(npc.x, npc.y, npc.z)) < 2.0 then
                isNearNPC = true
                QBCore.Functions.DrawText3D(npc.x, npc.y, npc.z + 1.0, "Press [H] to get a loan")

                if IsControlJustReleased(0, 74) then  -- 74 = H key
                    TriggerServerEvent('bankloan:getCreditAndLoans')
                end
            end
        end

        if not isNearNPC then Wait(1000) else Wait(0) end
    end
end)
