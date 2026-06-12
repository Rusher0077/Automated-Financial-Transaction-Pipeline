CREATE OR REPLACE TABLE dim_transaction_type AS 
SELECT 
  DISTINCT type AS transaction_type,
  CASE type
    WHEN 'CASH_IN'   THEN 'Deposit into account'
    WHEN 'CASH_OUT'  THEN 'Withdrawal from account'
    WHEN 'TRANSFER'  THEN 'Account-to-account transfer'
    WHEN 'PAYMENT'   THEN 'Merchant payment'
    WHEN 'DEBIT'     THEN 'Direct debit'
  END AS description
FROM transactions_with_dates