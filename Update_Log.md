Update Log: Bank Loan System for QB-Core
Version v1.0.2
Release Date: January, 25th, 2025

New Features
Credit System Integration:

Players now have a credit score that affects loan eligibility.
Added exports for checking, adding, and removing player credit, enabling integration with other scripts like dealerships.
Loans have specific credit requirements (requiredCredit) defined in Config.LoanOptions.
Dynamic Loan Menu:

Replaced HTML-based menu system with qb-menu for seamless integration (For Now Will Update).
Displays available loans based on player credit.
Loans with insufficient credit are displayed as "Insufficient Credit" and disabled.
Key Bind & Interaction Improvements:

Pressing H (default) near a loan location opens the loan menu if conditions are met.
Debug logs added for easier troubleshooting of key presses and menu functionality.
Debt Management:

Added /debit command to show a player's remaining debt.
Admin-only /remove_debit [player id] command to clear debt for a specific player.
Automatically deducts 50% of the paycheck towards loan repayment.
NPC System:

NPCs spawn at configured locations (Config.NPCSpawnLocations) using the Config.NPCModel.
NPCs are invincible, stationary, and interact with players to offer loans.
Custom Notifications:

Added structured notifications for loan approvals, rejections, and repayments.
Notifications use the player's configured currency symbol (Config.CurrencySymbol).
Enhancements
Secured Server Events:

All server events now validate inputs (e.g., loan amount, interest rate) to prevent abuse via Lua executors.
Added credit checks to ensure players cannot bypass loan requirements.
Permission checks implemented for admin commands.
Improved Debugging:

Added detailed debug messages to client and server logs for every critical action.
Logs include timestamps and helpful context (e.g., player credit, loan data).
Database Optimization:

Improved SQL schema:
Foreign key relationships and indexing for player_loans table.
Added credit column to players table to track player credit scores.
Streamlined queries to fetch player loans and update debt.
Configurable Settings:

Moved hardcoded settings to config.lua, including:
Loan locations and NPC spawn points.
Loan amounts, interest rates, and credit requirements.
Paycheck deduction percentages.

Bug Fixes:
Resolved SCRIPT ERROR: attempt to call a nil value (global 'DrawText3D').
Fixed SCRIPT ERROR: Execution of function reference in script host failed for /remove_debit command.
Corrected Uncaught SyntaxError: Invalid shorthand property initializer in script.js.
Addressed qb-menu menu not opening issue by validating server-to-client data flow.
Fixed incorrect loan amount calculations due to improper interest rate validation.
Resolved key press detection issues when interacting with loan locations.
Known Issues
None reported at this time. Please report bugs or issues on GitHub or via Discord.

Future Plans:
Add support for dynamic interest rates based on player credit.
Introduce penalties for late payments, affecting credit scores.
Implement a loan history feature accessible via a command or menu.
Expand integration with other scripts (e.g., housing and vehicle loans).

Contributors
[Bert5580]
Special thanks to the QB-Core community for feedback and testing.
