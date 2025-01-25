-- BankLoans.sql
-- SQL script to set up the database schema for the Bank Loans system with a credit system.

-- Add a `debit` column to the `players` table if it does not already exist
ALTER TABLE players 
ADD COLUMN IF NOT EXISTS debit DECIMAL(10,2) DEFAULT 0.00;

-- Add a `credit_score` column to the `players` table for the credit system
ALTER TABLE players 
ADD COLUMN IF NOT EXISTS credit_score INT DEFAULT 100;

-- Ensure `citizenid` in the `players` table is indexed for foreign key reference
ALTER TABLE players 
ADD INDEX IF NOT EXISTS idx_citizenid (citizenid);

-- Create a new table for detailed loan tracking
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Example: Insert a test loan for debugging purposes
-- DELETE this after testing
INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) VALUES
('TESTCITIZEN123', 5000, 0.02, 5100, 0);

-- Query example to calculate remaining debt for a player
-- Replace 'TESTCITIZEN123' with the actual citizen ID
SELECT total_debt - amount_paid AS remaining_debt 
FROM player_loans 
WHERE citizenid = 'TESTCITIZEN123';

-- Query to check and update the credit score of a player
-- Example: Add credit score upon repayment
UPDATE players 
SET credit_score = credit_score + 5 
WHERE citizenid = 'TESTCITIZEN123';

-- Example: Deduct credit score for missed payments
UPDATE players 
SET credit_score = credit_score - 10 
WHERE citizenid = 'TESTCITIZEN123';
