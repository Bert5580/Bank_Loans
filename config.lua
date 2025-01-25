Config = {}

-- Loan Locations
Config.LoanLocations = {
    vector3(243.3, 224.77, 107.29), -- LS Example location
    vector3(-111.95, 6469.14, 32.13),  -- PB Example location
    vector3(-2957.67, 476.33, 16.2) -- LS-FB Example location
}

-- NPC Spawn Locations
Config.NPCSpawnLocations = {
    vector4(244.24, 226.03, 106.29, 161.67),  -- LS NPC spawn location with heading
    vector4(-111.16, 6470.01, 31.63, 135.92),     -- PB NPC spawn location with heading
    vector4(-2961.08, 483.4, 15.7, 90.06)  -- LS-FB NPC spawn location with heading
}

-- NPC Model
Config.NPCModel = `cs_bankman` -- Shopkeeper NPC model

-- Loan Options
Config.LoanOptions = {
    {amount = 5000, interestRate = 0.02, requiredCredit = 400},   -- Loan of $5000 with 2% interest
    {amount = 10000, interestRate = 0.03, requiredCredit = 500}, -- Loan of $10000 with 3% interest
    {amount = 20000, interestRate = 0.04, requiredCredit = 600}, -- Loan of $20000 with 4% interest
    {amount = 50000, interestRate = 0.05, requiredCredit = 700}, -- Loan of $50000 with 5% interest
    {amount = 80000, interestRate = 0.06, requiredCredit = 800}, -- Loan of $80000 with 6% interest
    {amount = 100000, interestRate = 0.07, requiredCredit = 900},-- Loan of $100000 with 7% interest
    {amount = 150000, interestRate = 0.08, requiredCredit = 1000},-- Loan of $150000 with 8% interest
    {amount = 200000, interestRate = 0.09, requiredCredit = 1100},-- Loan of $200000 with 9% interest
    {amount = 250000, interestRate = 0.10, requiredCredit = 1200},-- Loan of $250000 with 10% interest
    {amount = 500000, interestRate = 0.11, requiredCredit = 1300},-- Loan of $500000 with 11% interest
    {amount = 750000, interestRate = 0.12, requiredCredit = 1400},-- Loan of $750000 with 12% interest
    {amount = 850000, interestRate = 0.13, requiredCredit = 1500},-- Loan of $850000 with 13% interest
    {amount = 100000000, interestRate = 0.14, requiredCredit = 1600} -- Loan of $100000000 with 14% interest
}

-- Paycheck Interval and Payback Percentage
Config.PaycheckInterval = 600000 -- Paycheck every 10 minutes (milliseconds)
Config.PaybackPercentage = 0.5  -- 50% of paycheck goes to loan repayment

-- Notification Configuration
Config.Notifications = {
    successColor = {r = 0, g = 255, b = 0},  -- Notification success color
    errorColor = {r = 255, g = 0, b = 0},    -- Notification error color
    duration = 5000 -- Duration of notifications in milliseconds
}

-- Credit System Configuration
Config.CreditSystem = {
    minCreditForLoan = 200, -- Minimum credit score required for loans
    creditGainOnRepayment = 5, -- Credit score gain per loan repayment
    creditLossOnDefault = 10, -- Credit score loss for missed payments
    defaultCredit = 100 -- Default starting credit score
}

-- Debug Mode
Config.Debug = false -- Enable debug mode for development

-- Currency Symbol
Config.CurrencySymbol = "$" -- Symbol to display for currency

-- Function: Add Loan Blips
function AddLoanBlips()
    for _, coord in pairs(Config.LoanLocations) do
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
        SetBlipSprite(blip, 108) -- Dollar sign icon
        SetBlipScale(blip, 1.0) -- Blip size
        SetBlipColour(blip, 2) -- Green color
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bank Loans") -- Blip name
        EndTextCommandSetBlipName(blip)

        if Config.Debug then
            print(string.format("Debug: Loan blip added at location x=%.2f, y=%.2f, z=%.2f", coord.x, coord.y, coord.z))
        end
    end
end

-- Function: Spawn NPCs
function SpawnLoanNPCs()
    local npcLocations = Config.NPCSpawnLocations
    local npcModel = Config.NPCModel

    -- Request and load the NPC model
    RequestModel(npcModel)
    local attempts = 0
    while not HasModelLoaded(npcModel) do
        Wait(10)
        attempts = attempts + 1
        if attempts > 500 then
            print("Error: NPC model failed to load after multiple attempts.")
            return
        end
    end

    if Config.Debug then
        print("Debug: NPC model loaded successfully.")
    end

    -- Spawn NPCs at all configured locations
    for _, location in pairs(npcLocations) do
        local npc = CreatePed(4, npcModel, location.x, location.y, location.z - 1.0, location.w, false, true)
        if npc and DoesEntityExist(npc) then
            SetEntityInvincible(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            FreezeEntityPosition(npc, true)
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, true)

            if Config.Debug then
                print(string.format("Debug: NPC spawned at location x=%.2f, y=%.2f, z=%.2f, heading=%.2f", location.x, location.y, location.z, location.w))
            end
        else
            print(string.format("Error: Failed to spawn NPC at location x=%.2f, y=%.2f, z=%.2f, heading=%.2f", location.x, location.y, location.z, location.w))
        end
    end

    -- Clean up the model to save memory
    SetModelAsNoLongerNeeded(npcModel)
end
