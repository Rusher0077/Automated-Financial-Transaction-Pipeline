CREATE OR REPLACE TABLE account_balance_snapshot AS 
WITH daily_activities AS (
    SELECT
        account_orig AS account_id,
        date AS snapshot_date,
        COUNT(*) AS daily_transaction_count,
        SUM(amount) AS daily_volume,
        max_by(bal_after_transaction, trans_id) AS closing_balance
    FROM fact_daily_transactions
    GROUP BY account_orig, date
)
SELECT 
    snapshot_date,
    account_id,
    daily_volume,
    closing_balance,
    daily_transaction_count,
    AVG(daily_transaction_count) OVER (
        PARTITION BY account_id 
        ORDER BY snapshot_date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30d_avg_count
FROM daily_activities