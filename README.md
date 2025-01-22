# Bank Loans Script for QB-Core

This FiveM resource provides a comprehensive bank loan system for servers using QB-Core. Players can take out loans, repay debts, and interact with NPC bankers at designated locations.

---

## Features

- Loan options with customizable amounts and interest rates.
- Dynamic debt tracking.
- Payment deductions from player paychecks.
- Configurable loan locations and NPCs.
- Debugging tools for development.
- Localized support for easy translation.

---

## Installation

1. **Download and Place Resource**:
   - Place the `Bank_Loans` folder in your FiveM server's `resources` directory.

2. **Add to Server Config**:
   - Add the following line to your `server.cfg`:
     ```plaintext
     ensure Bank_Loans
     ```

3. **Dependencies**:
   - Ensure the following resources are installed and running:
     - `qb-core`
     - `qb-menu`
     - `mysql-async`

4. **Database Setup**:
   - Add a `debit` column to your `players` table in the database:
     ```sql
     ALTER TABLE players ADD COLUMN debit DOUBLE DEFAULT 0;
     ```

5. **Optional: Localized Support**:
   - Modify `locales/en.lua` to add translations for other languages if required.

---

## Configuration

Edit the `config.lua` file to customize the resource settings:

- **Loan Locations**: Specify coordinates for loan markers and NPCs.
- **NPC Models**: Define NPC models for bankers.
- **Loan Options**: Configure loan amounts and interest rates.
- **Debug Mode**: Enable or disable debug messages.

Example configuration snippet:
```lua
Config = {
    LoanLocations = {
        vector3(242.38, 223.88, 106.79),
        vector3(-102.49, 6464.56, 32.13),
    },
    NPCSpawnLocations = {
        vector4(243.0, 224.0, 106.29, 0.0),
    },
    NPCModel = `s_m_m_bankman_01`,
    LoanOptions = {
        {amount = 5000, interestRate = 0.02},
        {amount = 10000, interestRate = 0.03},
    },
    Debug = true,
    CurrencySymbol = "$"
}
```

---

## Usage

### Player Commands
- `/debit`: Check remaining debt.

### Admin Commands
- `/remove_debit [playerID]`: Clear all debt for a specified player.

---

## Development

### Debugging
- Enable debug mode in `config.lua`:
  ```lua
  Config.Debug = true
  ```
- Debug messages will provide insights into loan interactions, NPC spawning, and database operations.

### Locales
- Modify or add translations in `locales/en.lua`.

### Known Issues
- Ensure `locales/en.lua` is properly loaded to avoid missing localization errors.

---

## Support
For assistance, please create an issue on the project repository or contact the development team.

---

## License
This project is licensed under the MIT License. See `LICENSE` for more details.

