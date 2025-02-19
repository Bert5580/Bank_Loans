Config = {}

-- Loan Locations
Config.LoanLocations = {
    vector3(243.3, 224.77, 107.29),
    vector3(-111.95, 6469.14, 32.13),
    vector3(-2957.67, 476.33, 16.2)
}

-- NPC Spawn Locations
Config.NPCSpawnLocations = {
    vector4(244.24, 226.03, 106.29, 161.67),
    vector4(-111.16, 6470.01, 31.63, 135.92),
    vector4(-2961.08, 483.4, 15.7, 90.06)
}

-- NPC Model
Config.NPCModel = `cs_bankman`

-- Loan System Settings
Config.EnableInterest = true -- If false, loans have no interest.
Config.MaxLoanAmount = 100000000 -- Maximum loan a player can take.
Config.MinCreditForLoan = 200  -- Minimum credit required for any loan.

-- Loan Options
Config.LoanOptions = {
    {amount = 5000, interestRate = 0.02, requiredCredit = 200},
    {amount = 10000, interestRate = 0.03, requiredCredit = 350},
    {amount = 20000, interestRate = 0.04, requiredCredit = 600},
    {amount = 50000, interestRate = 0.05, requiredCredit = 700},
    {amount = 80000, interestRate = 0.06, requiredCredit = 800},
    {amount = 100000, interestRate = 0.07, requiredCredit = 900},
    {amount = 150000, interestRate = 0.08, requiredCredit = 1000},
    {amount = 200000, interestRate = 0.09, requiredCredit = 1100},
    {amount = 250000, interestRate = 0.10, requiredCredit = 1200},
    {amount = 500000, interestRate = 0.11, requiredCredit = 1300},
    {amount = 750000, interestRate = 0.12, requiredCredit = 1400},
    {amount = 850000, interestRate = 0.13, requiredCredit = 1500},
    {amount = 100000000, interestRate = 0.14, requiredCredit = 1600}
}

-- Paycheck & Loan Repayment
Config.EnableAutoRepayment = true -- If true, loans are deducted automatically from paychecks.
Config.PaycheckInterval = 600000
Config.PaybackPercentage = 0.5

-- Notifications
Config.Notifications = {
    successColor = {r = 0, g = 255, b = 0},
    errorColor = {r = 255, g = 0, b = 0},
    duration = 5000
}

-- Credit System
Config.CreditSystem = {
    creditGainOnRepayment = 75,
    creditLossOnDefault = 25,
    defaultCredit = 200
}

-- Debug Mode
Config.Debug = true

-- Currency Symbol
Config.CurrencySymbol = "$"

-- Enable/Disable qb-target for interaction
Config.UseQBTarget = false

-- Function: Add Loan Blips
function AddLoanBlips()
    if not Config.LoanLocations or #Config.LoanLocations == 0 then
        print("[ERROR] No loan locations configured for blips.")
        return
    end
    for _, coord in pairs(Config.LoanLocations) do
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
        SetBlipSprite(blip, 108)
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bank Loans")
        EndTextCommandSetBlipName(blip)
        if Config.Debug then
            print(string.format("[DEBUG] Loan blip added at x=%.2f, y=%.2f, z=%.2f", coord.x, coord.y, coord.z))
        end
    end
end

-- Function: Spawn NPCs with qb-target compatibility
function SpawnLoanNPCs()
    if not Config.NPCSpawnLocations or #Config.NPCSpawnLocations == 0 then
        print("[ERROR] No NPC spawn locations configured.")
        return
    end
    if not Config.NPCModel then
        print("[ERROR] NPC model is not defined in the configuration.")
        return
    end
    RequestModel(Config.NPCModel)
    local attempts = 0
    while not HasModelLoaded(Config.NPCModel) do
        Wait(10)
        attempts = attempts + 1
        if attempts > 500 then
            print("[ERROR] NPC model failed to load after multiple attempts.")
            return
        end
    end
    if Config.Debug then
        print("[DEBUG] NPC model loaded successfully.")
    end
    for _, location in pairs(Config.NPCSpawnLocations) do
        local npc = CreatePed(4, Config.NPCModel, location.x, location.y, location.z - 1.0, location.w, false, true)
        if npc and DoesEntityExist(npc) then
            SetEntityInvincible(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            FreezeEntityPosition(npc, true)
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, true)

            if Config.UseQBTarget then
                exports['qb-target']:AddTargetEntity(npc, {
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
            end

            if Config.Debug then
                print(string.format("[DEBUG] NPC spawned at x=%.2f, y=%.2f, z=%.2f, heading=%.2f", location.x, location.y, location.z, location.w))
            end
        else
            print(string.format("[ERROR] Failed to spawn NPC at x=%.2f, y=%.2f, z=%.2f, heading=%.2f", location.x, location.y, location.z, location.w))
        end
    end
    SetModelAsNoLongerNeeded(Config.NPCModel)
end
