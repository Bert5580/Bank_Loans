# Bank Loans System for QB-Core

## 📌 Overview
The **Bank Loans System** is a fully integrated **loan and credit** system designed for **QB-Core**. It allows players to take loans, repay them through paychecks, and manage their credit.

## 🔥 Features:
- **Fully Integrated Loan System**
  - Tracks **credit** and **debit** in the database.
  - Interest rates applied dynamically.
- **Automatic Paycheck Deduction**
  - Repayment system built into the economy.
- **Admin Credit Management**
  - Add or remove credit via commands.
- **NPC-Based Loan Interactions**
  - Players can visit NPCs to apply for loans.
- **Dynamic Loan Configurations**
  - Adjustable interest rates, credit requirements, and repayment amounts.
- **Multi-Language Support**
  - Locales available for translations.
- **Debug Mode**
  - Logs events, errors, and system interactions.

---

# 🔗 Integration Guide
To **increase a player's credit** from another script (e.g., after completing a job or mission), use:

```lua
TriggerServerEvent('bankloan:addCredit', source, creditAmount)
```

Example usage in another script:
```lua
RegisterNetEvent('job:bonus')
AddEventHandler('job:bonus', function()
    local playerId = source
    local creditBonus = 10 -- Increase by 10 points
    TriggerServerEvent('bankloan:updateCredit', playerId, creditBonus, "Job Performance Bonus")
end)
```

---

# 📖 Commands List

### **Player Commands:**
| Command | Description |
|---------|-------------|
| `/check_credit` | Displays the player's current credit. |
| `/check_debit` | Shows the remaining debt the player needs to repay. |
| `/pay_loan [amount]` | Pays off a specified amount towards the loan. |
| `/grant_loan [player_id] [amount] [interest]` | Grants a loan to a specific player with an interest rate. |

### **Admin Commands:**
| Command | Description |
|---------|-------------|
| `/addcredit [player_id] [amount]` | Adds credit to a player. |
| `/removecredit [player_id] [amount]` | Removes credit from a player. |
| `/add_debit [player_id] [amount]` | Adds a debt amount to a player. |
| `/remove_debit [player_id] [amount]` | Removes a specified debt amount from a player. |

---

# 📜 Update Log

## **Version Qv1.0.4 - [February 10, 2025]**
### **New Features:**
- Added `/grant_loan [player_id] [amount] [interest]` for admins to issue loans.
- `/pay_loan` now **properly deducts money** and updates **remaining debt**.
- Players **gain 150 credit** when they fully pay off their loans.

### **Bug Fixes & Improvements:**
- `/check_debit` now **accurately reflects loan payments**.
- Added `/add_debit` and `/remove_debit` for better debt management.
- Improved **credit and debit tracking** in the database.
- **NPC interactions and menus** now work consistently.

---

## **Version Qv1.0.3 - [January 25, 2025]**
### **New Features:**
- Added **multi-language localization** (`Locales/en.lua`).
- Configurable loan options (`Config.LoanOptions`).
- NPC loan interaction system.

### **Bug Fixes:**
- Fixed missing `citizenid` references in SQL queries.
- Corrected `player_loans` table creation issues.

---

## 🚀 Future Updates
- **ATM Loan Repayments**.
- **More Loan Locations**.
- **Better Interest Rate Calculations**.

### 💡 Need help?
Join our support community or open an issue!

