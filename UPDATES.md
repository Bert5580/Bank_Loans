# UPDATES.log
# Bank Loans System - Update Log
# Last Updated: [February 18, 2025]

# Updating the UPDATES.log content with Qv1.0.7 updates

updates_log_content = """
UPDATES.log - Bank Loans System

Qv1.0.7 - [February 18, 2025]
- Fixed bug where selecting a loan option did not add money or show notifications.
- Ensured loan transactions properly deduct from the database and update the player's balance.
- Improved the `/check_debit` command to correctly fetch and display player debt.
- Optimized server-side performance by reducing redundant queries.
- Enhanced security to prevent exploits in loan granting and repayments.
- Fixed issue where `/grant_loan` command sometimes failed due to interest rate parsing.
- Improved NPC spawn handling for better reliability.

Qv1.0.6 - [February 12, 2025]
- Added feature to display credit info upon request.
- Improved "Press H to Get a Loan" system for easier interaction.
- Updated the loan repayment command to handle incomplete payments more effectively.
- Fixed issues with "check_debit" command and made it functional.
- Added new NPC interaction prompts to guide players.
- Improved menu handling when selecting loan options via qb-menu.
- Fixed issues with notifications after loan payment.

Qv1.0.5 - [February 10, 2025]
- Added NPC loan interaction system using qb-target.
- Updated loan repayment system to deduct money from player's bank account.
- Grant loan command now supports proper error handling.
- Players can now fully repay loans and earn credit.
- Fixed issues with menu loading when interacting with NPCs.
- Enhanced error handling and debugging logs.

Qv1.0.4 - [February 8, 2025]
- Introduced command structure for managing player credit and debt.
- Added support for the new database structure and functions.
- Introduced new admin commands for adding and removing credit/debt.
- Updated loan functionality to include interest and remaining balance tracking.

Qv1.0.3 - [January 25, 2025]
- Initial release with loan functionality and basic menu handling.
- Added player loan database schema and tracking.
- Introduced NPC model interaction for loans.
- Added essential admin commands.

--------------------------------------------------------
# 🚀 Future Updates
- **ATM Loan Repayments**.
- **More Loan Locations**.
- **Better Interest Rate Calculations**.
- **Player Banker Management**.

### 💡 Need Help?
Join our support community or open an issue!
