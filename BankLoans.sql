-- BankLoans.sql
-- SQL script to set up the database schema for the Bank Loans system with a credit system.

-- ===========================================
-- STEP 1: Add Missing Columns to `users`
-- ===========================================

-- Add a `debit` column to the `users` table for tracking loan debt
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS debit DECIMAL(10,2) DEFAULT 0.00;

-- Add a `credit_score` column to the `users` table for the credit system
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS credit_score INT DEFAULT 100;

-- Ensure `identifier` in the `users` table is indexed for references
ALTER TABLE users 
ADD UNIQUE INDEX IF NOT EXISTS idx_identifier (identifier);

-- ===========================================
-- STEP 2: Define `player_loans` Table
-- ===========================================

-- Create the `player_loans` table for detailed loan tracking
CREATE TABLE IF NOT EXISTS player_loans (
    id INT AUTO_INCREMENT PRIMARY KEY,                    -- Unique ID for each loan
    identifier VARCHAR(50) NOT NULL,                     -- Links to users.identifier
    loan_amount DOUBLE NOT NULL,                         -- Loan amount
    interest_rate DOUBLE NOT NULL DEFAULT 0.05,          -- Default interest rate: 5%
    total_debt DOUBLE NOT NULL,                          -- Total debt (loan + interest)
    amount_paid DOUBLE DEFAULT 0,                        -- Amount paid so far
    date_taken DATETIME DEFAULT CURRENT_TIMESTAMP,       -- Date when the loan was taken
    last_payment DATETIME DEFAULT NULL                   -- Date of the last payment
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ===========================================
-- STEP 3: Add Test Data
-- ===========================================

-- Insert a test loan into the `player_loans` table (remove this after testing)
INSERT INTO player_loans (identifier, loan_amount, interest_rate, total_debt, amount_paid) 
VALUES ('TESTIDENTIFIER123', 5000, 0.05, 5250, 0);

-- ===========================================
-- STEP 4: Example Queries for Loan Management
-- ===========================================

-- Calculate the remaining debt for a player
SELECT total_debt - amount_paid AS remaining_debt 
FROM player_loans 
WHERE identifier = 'TESTIDENTIFIER123';

-- Update the credit score when a player repays a loan
UPDATE users 
SET credit_score = credit_score + 5 
WHERE identifier = 'TESTIDENTIFIER123';

-- Deduct the credit score for missed payments
UPDATE users 
SET credit_score = credit_score - 10 
WHERE identifier = 'TESTIDENTIFIER123';
