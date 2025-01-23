# QB-Core Bank Loans System for QB-Core

This project is a FiveM script designed to integrate a loan system into servers running the QB-Core framework. The system allows players to take loans, manage debts, and repay them over time with configurable interest rates.

## Features

- **Loan Options:**
  - Multiple loan options with predefined amounts and interest rates.
  - Loans include configurable interest rates.
- **Debt Management:**
  - Tracks debt balances and repayment progress.
  - Repay loans over time, with payments deducted from player paychecks.
- **NPC Integration:**
  - NPCs at designated locations to interact with for taking loans.
- **Blip and Marker Integration:**
  - Blips and markers for loan locations on the map.
- **Player Commands:**
  - `/debit`: View remaining debt.
  - `/remove_debit [player ID]`: Admin command to clear a player's debt.
- **Database Integration:**
  - Tracks loans in the `player_loans` database table.
- **Debug Mode:**
  - Configurable debug prints for testing and troubleshooting.

## Requirements

- [QB-Core Framework](https://github.com/qbcore-framework/qb-core)
- [oxmysql](https://github.com/overextended/oxmysql)
- [qb-menu](https://github.com/qbcore-framework/qb-menu)

## Installation

1. Clone or download this repository.
2. Add the `qb-BankLoans.sql` file to your database:
   ```sql
   source BankLoans.sql;
   ```
3. Place the script in your `resources` folder.
4. Add the resource to your `server.cfg`:
   ```cfg
   ensure Bank_Loans
   ```

## Configuration

All configuration options can be found in `config.lua`. The key settings include:

- **Loan Locations:** Define coordinates for NPCs and loan blips.
- **NPC Models:** Customize NPC models and spawn locations.
- **Loan Options:** Configure available loan amounts and interest rates.
- **Paycheck Interval and Repayment:** Define how often payments are deducted and the percentage deducted.
- **Notifications:** Customize notification colors and durations.

### Example Configuration
```lua
Config.LoanLocations = {
    vector3(243.3, 224.77, 107.29),
    vector3(-111.95, 6469.14, 32.13),
    vector3(-2957.67, 476.33, 16.2)
}

Config.NPCSpawnLocations = {
    vector4(244.24, 226.03, 106.29, 161.67),
    vector4(-111.16, 6470.01, 31.63, 135.92),
    vector4(-2961.08, 483.4, 15.7, 90.06)
}

Config.LoanOptions = {
    {amount = 5000, interestRate = 0.02},
    {amount = 10000, interestRate = 0.03},
    {amount = 20000, interestRate = 0.04},
    {amount = 50000, interestRate = 0.05}
}
```

## Usage

### Taking a Loan
1. Approach a loan NPC.
2. Press `H` (configurable) to interact with the NPC.
3. Select a loan option from the menu.

### Checking Debt
- Use the `/debit` command to see your remaining debt.

### Clearing Debt (Admins Only)
- Use `/remove_debit [player ID]` to clear a player's debt.

## Database Structure

### `players` Table
The `players` table includes a `debit` column to track the total debt for each player:
```sql
ALTER TABLE players ADD COLUMN IF NOT EXISTS debit DECIMAL(10,2) DEFAULT 0.00;
```

### `player_loans` Table
Tracks detailed loan information:
```sql
CREATE TABLE IF NOT EXISTS player_loans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(11) NOT NULL,
    loan_amount DOUBLE NOT NULL,
    interest_rate DOUBLE NOT NULL,
    total_debt DOUBLE NOT NULL,
    amount_paid DOUBLE DEFAULT 0,
    date_taken DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_payment DATETIME DEFAULT NULL,
    FOREIGN KEY (citizenid) REFERENCES players(citizenid) ON DELETE CASCADE
);
```

## Debugging

Enable `Config.Debug = true` in `config.lua` to view debug prints for events, loan processing, and database interactions.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

---

For any issues or questions, feel free to open an issue on the repository or reach out to the development team.
