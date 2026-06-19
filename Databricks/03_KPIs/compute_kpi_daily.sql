CREATE OR REPLACE TABLE kpi_daily AS 

WITH daily_base AS (
    SELECT 
        date AS                                         report_date,
        SUM(amount) AS                                  total_volume,
        COUNT(*) AS                                     transaction_count, 
        SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) 
        * 100.0 / COUNT(*)                              fraud_flag_rate,
        
        SUM(amount)/COUNT(*)                            avg_transaction_size    

    FROM fact_daily_transactions
    GROUP BY date 
)

SELECT
  report_date,
  total_volume,
  transaction_count,
  fraud_flag_rate,
  avg_transaction_size,
  ROUND(
    (total_volume - LAG(total_volume) OVER (ORDER BY report_date)) * 100
    / LAG(total_volume) OVER (ORDER BY report_date), 2         
  )                                                     AS dod_volume_change_pct,
  ROUND(
    (transaction_count - LAG(transaction_count) OVER (ORDER BY report_date)) * 100
    / LAG(transaction_count) OVER (ORDER BY report_date), 2         
  )                                                     AS dod_count_change_pct

FROM daily_base
ORDER BY report_date