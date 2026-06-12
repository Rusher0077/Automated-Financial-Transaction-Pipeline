-- Schema check
SELECT * FROM pay_slim LIMIT 5;
DESCRIBE pay_slim;

-- Row count validation
SELECT COUNT(*) AS total_rows FROM pay_slim;

-- Null check on critical columns
SELECT
  COUNT(*) AS total_rows,
  COUNT(CASE WHEN step IS NULL THEN 1 END) AS null_step,
  COUNT(CASE WHEN type IS NULL THEN 1 END) AS null_type,
  COUNT(CASE WHEN amount IS NULL THEN 1 END) AS null_amount,
  COUNT(CASE WHEN nameOrig IS NULL THEN 1 END) AS null_nameOrig,
  COUNT(CASE WHEN nameDest IS NULL THEN 1 END) AS null_nameDest,
  COUNT(CASE WHEN isFraud IS NULL THEN 1 END) AS null_isFraud,
  COUNT(CASE WHEN isFlaggedFraud IS NULL THEN 1 END) AS null_isFlaggedFraud
FROM pay_slim;

-- Transaction type breakdown
SELECT type, COUNT(*) AS count
FROM pay_slim
GROUP BY type
ORDER BY count DESC;

-- Date offset validation
SELECT day_number, simulated_date, count(*) as row_count
FROM transactions_with_dates
GROUP BY day_number, simulated_date
ORDER BY day_number