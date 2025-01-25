-- BankLoans.sql
-- SQL script to set up the database schema for the Bank Loans system with a credit system.

-- ===========================================
-- STEP 1: Add Missing Columns to `players`
-- ===========================================

-- Add a `debit` column to the `players` table for tracking loan debt
ALTER TABLE players 
ADD COLUMN IF NOT EXISTS debit DECIMAL(10,2) DEFAULT 0.00;

-- Add a `credit_score` column to the `players` table for the credit system
ALTER TABLE players 
ADD COLUMN IF NOT EXISTS credit_score INT DEFAULT 100;

-- Ensure `citizenid` in the `players` table is indexed for references
ALTER TABLE players 
ADD UNIQUE INDEX IF NOT EXISTS idx_citizenid (citizenid);

-- ===========================================
-- STEP 2: Define `player_loans` Table
-- ===========================================

-- Create the `player_loans` table for detailed loan tracking
CREATE TABLE IF NOT EXISTS player_loans (
    id INT AUTO_INCREMENT PRIMARY KEY,                    -- Unique ID for each loan
    citizenid VARCHAR(50) NOT NULL,                      -- Links to players.citizenid
    loan_amount DOUBLE NOT NULL,                         -- Loan amount
    interest_rate DOUBLE NOT NULL DEFAULT 0.05,          -- Default interest rate: 5%
    total_debt DOUBLE NOT NULL,                          -- Total debt (loan + interest)
    amount_paid DOUBLE DEFAULT 0,                        -- Amount paid so far
    date_taken DATETIME DEFAULT CURRENT_TIMESTAMP,       -- Date when the loan was taken
    last_payment DATETIME DEFAULT NULL,                  -- Date of the last payment
    FOREIGN KEY (citizenid) REFERENCES players(citizenid) ON DELETE CASCADE -- Foreign key constraint
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ===========================================
-- STEP 3: Add Test Data
-- ===========================================

-- Insert a test loan into the `player_loans` table (remove this after testing)
INSERT INTO player_loans (citizenid, loan_amount, interest_rate, total_debt, amount_paid) 
VALUES ('TESTCITIZEN123', 5000, 0.05, 5250, 0);

-- ===========================================
-- STEP 4: Example Queries for Loan Management
-- ===========================================

-- Calculate the remaining debt for a player
SELECT total_debt - amount_paid AS remaining_debt 
FROM player_loans 
WHERE citizenid = 'TESTCITIZEN123';

-- Update the credit score when a player repays a loan
UPDATE players 
SET credit_score = credit_score + 5 
WHERE citizenid = 'TESTCITIZEN123';

-- Deduct the credit score for missed payments
UPDATE players 
SET credit_score = credit_score - 10 
WHERE citizenid = 'TESTCITIZEN123';
