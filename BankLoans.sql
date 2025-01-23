-- BankLoans.sql
-- SQL script to set up the necessary database schema and configuration for the Bank Loans system.

-- Add a `debit` column to the `players` table if it does not already exist
ALTER TABLE players 
ADD COLUMN IF NOT EXISTS debit DECIMAL(10,2) DEFAULT 0.00;

-- Ensure `citizenid` in the `players` table is indexed for foreign key reference
ALTER TABLE players 
ADD INDEX IF NOT EXISTS idx_citizenid (citizenid);

-- Create a new table for detailed loan tracking
CREATE TABLE IF NOT EXISTS player_loans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(11) NOT NULL,
    loan_amount DOUBLE NOT NULL CHECK (loan_amount > 0),
    interest_rate DOUBLE NOT NULL CHECK (interest_rate >= 0),
    total_debt DOUBLE NOT NULL CHECK (total_debt >= 0),
    amount_paid DOUBLE DEFAULT 0 CHECK (amount_paid >= 0),
    date_taken DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_payment DATETIME DEFAULT NULL,
    FOREIGN KEY (citizenid) REFERENCES players(citizenid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Ensure the foreign key index exists for the `player_loans` table
ALTER TABLE player_loans ADD INDEX IF NOT EXISTS idx_citizenid (citizenid);

-- Optional: Add a test entry to the players table for debugging purposes
INSERT IGNORE INTO players (citizenid, name, license, money, charinfo, job, gang, position, metadata, inventory) 
VALUES ('TESTCITIZEN123', 'Test User', 'license:test123', '{}', '{}', '{}', '{}', '{}', '{}', '{}');

-- Add a valid test loan to the player_loans table for debugging purposes
INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) 
VALUES ('TESTCITIZEN123', 5000, 0.02, 5100, 0);

-- Query example to calculate remaining debt for a specific player
-- Replace 'TESTCITIZEN123' with the actual citizen ID
SELECT total_debt - amount_paid AS remaining_debt 
FROM player_loans 
WHERE citizenid = 'TESTCITIZEN123';

-- Query example to calculate remaining debt for all players
SELECT citizenid, total_debt - amount_paid AS remaining_debt 
FROM player_loans;

-- Optional: Enable Slow Query Log for Performance Monitoring
-- SET GLOBAL slow_query_log = 1;
-- SET GLOBAL long_query_time = 0.1; -- Log queries taking longer than 100ms
