Locales = {}

-- English Locale
Locales['en'] = {
    -- Loan Interactions
    ['press_h'] = 'Press H To Get A Loan', -- Prompt for loan interaction
    ['confirm_loan'] = 'Are you sure you want to continue?\nNumpad1: Yes | Numpad2: No', -- Loan confirmation prompt
    ['loan_granted'] = 'You have received a loan of %s%s', -- Message when loan is granted (currency symbol and amount)
    ['debt_remaining'] = 'Remaining debt: %s%s', -- Display remaining debt (currency symbol and amount)
    ['debt_paid'] = 'You have fully repaid your loan!', -- Success message for full loan repayment
    ['error_no_funds'] = 'You do not have enough funds to make this payment', -- Insufficient funds message
    ['success_payment'] = 'Payment of %s%s made successfully', -- Payment confirmation (currency symbol and amount)
    ['notify_debit_command'] = 'Your remaining debt is: %s%s', -- Notification for debt command
    ['loan_interest'] = 'Interest rate: %s%%', -- Display loan interest rate
    ['insufficient_credit'] = 'Your credit score is too low to take this loan. Required credit: %s', -- Low credit score warning

    -- NPC Debugging
    ['npc_spawned'] = 'NPC spawned successfully at location: x=%.2f, y=%.2f, z=%.2f, heading=%.2f', -- NPC spawn success log
    ['npc_failed_spawn'] = 'Error: Failed to spawn NPC at location: x=%.2f, y=%.2f, z=%.2f, heading=%.2f', -- NPC spawn failure log
    ['npc_model_failed'] = 'Error: NPC model failed to load after multiple attempts', -- NPC model load failure
    ['npc_model_loaded'] = 'NPC model loaded successfully', -- NPC model load success log

    -- Loan Menu
    ['loan_menu_opened'] = 'Opening loan menu', -- Log message when loan menu is opened
    ['loan_menu_closed'] = 'Loan menu closed', -- Log message when loan menu is closed

    -- Blip and Marker Debugging
    ['blip_added'] = 'Blip added at location: x=%.2f, y=%.2f, z=%.2f', -- Log message for blip creation
    ['distance_to_loan_location'] = 'Distance to loan location: %.2f', -- Log for player proximity to loan location

    -- Credit System
    ['credit_added'] = 'Your credit score has increased by %s.', -- Message when credit score is increased
    ['credit_removed'] = 'Your credit score has decreased by %s.', -- Message when credit score is decreased
    ['current_credit'] = 'Your current credit score is: %s.', -- Message showing current credit score

    -- General Notifications
    ['action_success'] = 'Action completed successfully', -- General success message
    ['action_failed'] = 'Action could not be completed' -- General failure message
}

-- Placeholder for future translations (example: French Locale)
-- Locales['fr'] = {
--     ['press_h'] = 'Appuyez sur H pour obtenir un prêt',
--     -- Add more translations here
-- }
