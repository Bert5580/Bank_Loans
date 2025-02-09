Locales = {}

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
    
    -- Debt Management
    ['debt_payment_success'] = 'Successfully paid %s%s towards your debt.',
    ['debt_payment_failure'] = 'Payment failed. Please try again.',
    ['debt_removed_admin'] = 'Admin has removed %s%s from your debt.',
    ['debt_added_admin'] = 'Admin has added %s%s to your debt.',
    
    -- Admin Notifications
    ['admin_granted_loan'] = 'Loan of %s%s granted to Player ID: %s with %.2f%% interest.',
    ['admin_removed_debit'] = 'Removed %s%s of debt from Player ID: %s. Remaining Debt: %s%s.',
    ['admin_added_debit'] = 'Added %s%s debt to Player ID: %s.',
    
    -- Commands
    ['command_check_debt'] = 'Use /check_debit to check your remaining debt.',
    ['command_pay_loan'] = 'Use /pay_loan [amount] to pay off your loan.',
    ['command_grant_loan'] = 'Use /grant_loan [player id] [amount] [interest rate] to grant a loan.',
    ['command_remove_debit'] = 'Use /remove_debit [player id] [amount] to remove debt.',
    ['command_add_debit'] = 'Use /add_debit [player id] [amount] to add debt.'
}
