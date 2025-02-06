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
    ['loan_menu_header'] = 'Bank Loan Options',
    ['loan_menu_available_credit'] = 'Available Credit: %s.',
    
    -- Debt Management
    ['debt_fully_paid'] = 'You have fully paid off your debt!',
    ['debt_payment_success'] = 'Successfully paid %s%s towards your debt.',
    ['debt_payment_failure'] = 'Payment failed. Please try again.',
    ['debt_check_command'] = 'Your current remaining debt: %s%s.',
    ['debt_removed_admin'] = 'Admin has removed %s%s from your debt.',
    ['debt_added_admin'] = 'Admin has added %s%s to your debt.',
    ['debt_cleared'] = 'All debt has been cleared!',
    ['credit_reward_on_payment'] = 'You have earned 150 credit for fully repaying your debt!',
    
    -- Credit System
    ['credit_added'] = 'Your credit score has increased by %s.',
    ['credit_removed'] = 'Your credit score has decreased by %s.',
    ['current_credit'] = 'Your current credit score is: %s.',
    
    -- Admin Notifications
    ['admin_granted_loan'] = 'Loan of %s%s granted to Player ID: %s with %.2f%% interest.',
    ['admin_failed_grant'] = 'Failed to grant loan.',
    ['admin_removed_debit'] = 'Removed %s%s of debt from Player ID: %s. Remaining Debt: %s%s.',
    ['admin_added_debit'] = 'Added %s%s debt to Player ID: %s.',
    
    -- General Notifications
    ['action_success'] = 'Action completed successfully.',
    ['action_failed'] = 'Action could not be completed.',
    
    -- Blip and Marker Debugging
    ['blip_added'] = 'Blip added at location: x=%.2f, y=%.2f, z=%.2f.',
    ['distance_to_loan_location'] = 'Distance to loan location: %.2f.',
    
    -- NPC Debugging
    ['npc_spawned'] = 'NPC spawned successfully at location: x=%.2f, y=%.2f, z=%.2f, heading=%.2f.',
    ['npc_failed_spawn'] = 'Error: Failed to spawn NPC at location: x=%.2f, y=%.2f, z=%.2f, heading=%.2f.',
    ['npc_model_failed'] = 'Error: NPC model failed to load after multiple attempts.',
    ['npc_model_loaded'] = 'NPC model loaded successfully.',

    -- Loan Menu (qb-menu)
    ['loan_menu_opened'] = 'Opening loan menu...',
    ['loan_menu_closed'] = 'Loan menu closed.',
    ['loan_menu_select_option'] = 'Select a loan option:',
    ['loan_menu_loan_amount'] = 'Loan Amount: %s%s',
    ['loan_menu_interest_rate'] = 'Interest Rate: %.2f%%',
    ['loan_menu_required_credit'] = 'Required Credit: %s',
    
    -- Commands
    ['command_check_debt'] = 'Use /check_debit to check your remaining debt.',
    ['command_pay_loan'] = 'Use /pay_loan [amount] to pay off your loan.',
    ['command_grant_loan'] = 'Use /grant_loan [player id] [amount] [interest rate] to grant a loan.',
    ['command_remove_debit'] = 'Use /remove_debit [player id] [amount] to remove debt from a player.',
    ['command_add_debit'] = 'Use /add_debit [player id] [amount] to add debt to a player.',
    ['command_check_credit'] = 'Use /check_credit to view your current credit score.',
    ['command_add_credit'] = 'Use /addcredit [player id] [amount] to add credit to a player.',
    ['command_remove_credit'] = 'Use /removecredit [player id] [amount] to remove credit from a player.'
}
