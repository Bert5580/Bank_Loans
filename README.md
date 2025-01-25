# Update Log

## Version 1.0.3 - [January 25, 2025]
### **New Features**
- Fully integrated ESX Legacy compatibility for the **Bank Loans** system.
- Added support for multi-language localization with placeholders for future translations (e.g., `Locales.lua`).
- Introduced dynamic loan options configured via `Config.LoanOptions`:
  - Loans now have distinct amounts, interest rates, and credit requirements.
  - Users are notified of insufficient credit scores when attempting loans.
  
### **Possible Problems To Remove**
- You May Have To Remove This Line if The Import Fails (Without "--"),-- ALTER TABLE users 
ADD UNIQUE INDEX IF NOT EXISTS idx_identifier (identifier);

### **Improvements**
- Enhanced debug logging for easier troubleshooting:
  - Logs for NPC spawning, blip creation, and menu interactions.
  - Debug messages now include timestamps and severity levels.
- Optimized NPC spawning:
  - Added error handling for missing or invalid NPC models.
  - NPCs now have predefined scenarios (`WORLD_HUMAN_CLIPBOARD`).
- Simplified blip creation for loan locations with clearer debug logs.
- Updated `Config.lua` with better documentation for parameters like `CurrencySymbol`, `PaycheckInterval`, and `PaybackPercentage`.
- Improved `Locales.lua`:
  - Standardized keys.
  - Enhanced comments for placeholder strings like `%s` and `%.2f`.

### **Bug Fixes**
- Fixed missing column references (`citizenid` to `identifier`) in SQL queries.
- Resolved `player_loans` table creation issues:
  - Corrected foreign key relationships with `users`.
  - Ensured `loan_amount`, `total_debt`, and `amount_paid` are non-negative.
- Patched paycheck deduction logic:
  - Correctly handles partial payments and outstanding loan amounts.
  - Prevents unnecessary deductions for players with no debt.
- Added safeguards to prevent crashes due to missing configurations (e.g., `NPCModel` or `LoanLocations`).

### **SQL Updates**
- Updated database schema for compatibility with ESX Legacy:
  - Added `credit_score` and `debit` columns to the `users` table.
  - Created `player_loans` table for detailed loan tracking.
- Included fallback queries to verify table and column existence before execution.
- Provided example SQL queries for testing loan operations (e.g., repayment, credit score updates).

### **Commands Added**
- `/debit`: Check remaining debt.
- `/remove_debit`: Admin-only command to clear a player's debt.

### **Known Issues**
- None reported.

---

## Version 1.0.3 - [October 10, 2024]
### **Initial Features**
- Introduced the **Bank Loans** system for QBCore framework.
- Configurable loan options with support for interest rates and credit requirements.
- NPC-based loan interaction at predefined locations.
- Debug mode for logging and troubleshooting.

---

## Notes
- Please report any bugs or issues to the development team.
- Future updates will focus on adding ATM loan repayments and multi-language localization support.
