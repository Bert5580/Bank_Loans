Locales = {}

-- English Locale
Locales['en'] = {
    -- Loan Interactions
    ['press_h'] = 'Press [H] To Get A Loan',
    ['confirm_loan'] = 'Are you sure you want to continue?\nNumpad1: Yes | Numpad2: No',
    ['loan_granted'] = 'You have received a loan of %s%s.',
    ['debt_remaining'] = 'Remaining debt: %s%s.',
    ['debt_paid'] = 'You have fully repaid your loan!',
    ['error_no_funds'] = 'You do not have enough funds to make this payment.',
    ['success_payment'] = 'Payment of %s%s made successfully.',
    ['notify_debit_command'] = 'Your remaining debt is: %s%s.',
    ['loan_interest'] = 'Interest rate: %s%%.',
    ['insufficient_credit'] = 'Your credit score is too low to take this loan. Required credit: %s.',
    ['credit_received'] = 'You have received %s credit for repaying your loan.',

    -- NPC Debugging
    ['npc_spawned'] = 'NPC spawned successfully at location: x=%.2f, y=%.2f, z=%.2f, heading=%.2f.',
    ['npc_failed_spawn'] = 'Error: Failed to spawn NPC at location: x=%.2f, y=%.2f, z=%.2f, heading=%.2f.',
    ['npc_model_failed'] = 'Error: NPC model failed to load after multiple attempts.',
    ['npc_model_loaded'] = 'NPC model loaded successfully.',

    -- Loan Menu
    ['loan_menu_opened'] = 'Opening loan menu.',
    ['loan_menu_closed'] = 'Loan menu closed.',
    ['loan_option'] = 'Loan: %s%s | Interest: %s%% | Required Credit: %s.',

    -- Blip and Marker Debugging
    ['blip_added'] = 'Blip added at location: x=%.2f, y=%.2f, z=%.2f.',
    ['distance_to_loan_location'] = 'Distance to loan location: %.2f.',

    -- Credit System
    ['credit_added'] = 'Your credit score has increased by %s.',
    ['credit_removed'] = 'Your credit score has decreased by %s.',
    ['current_credit'] = 'Your current credit score is: %s.',

    -- General Notifications
    ['action_success'] = 'Action completed successfully.',
    ['action_failed'] = 'Action could not be completed.',

    -- Admin Commands
    ['admin_add_credit'] = 'Added %s credit to player %s.',
    ['admin_remove_credit'] = 'Removed %s credit from player %s.',
    ['admin_grant_loan'] = 'Granted loan of %s%s with %s%% interest to player %s.',
    ['admin_remove_debit'] = 'Removed %s%s from player %s's debt.',
    ['admin_add_debit'] = 'Added %s%s to player %s's debt.'
}

-- Placeholder for future translations (example: French Locale)
-- Locales['fr'] = {
--     ['press_h'] = 'Appuyez sur [H] pour obtenir un prêt.',
--     -- Add more translations here
-- }
