CREATE OR REPLACE TABLE kpi_weekly AS 

WITH weekly_base AS (
    SELECT
        date_trunc('week', date)                                 AS week_start,
        COUNT(DISTINCT date)                                     AS days_in_week,
        SUM(amount)                                              AS total_volume,
        COUNT(*)                                                 AS transaction_count,
        SUM(CASE WHEN transaction_type = 'CASH_IN'  THEN amount ELSE 0 END)    AS cash_in_volume,
        SUM(CASE WHEN transaction_type = 'CASH_OUT' THEN amount ELSE 0 END)    AS cash_out_volume,
        SUM(CASE WHEN transaction_type = 'TRANSFER' THEN amount ELSE 0 END)    AS transfer_volume
    FROM fact_daily_transactions
    GROUP BY date_trunc('week', date)
),
account_weekly_count AS (
    SELECT 
        date_trunc('week', date)                                 AS week_start,
        account_orig                                             AS account_id,
        COUNT(*)                                                 AS tx_count
    FROM fact_daily_transactions
    GROUP BY date_trunc('week', date), account_orig
),
ranked_accounts AS (
    SELECT 
        week_start,
        account_id,
        tx_count,
        row_number() OVER (PARTITION BY week_start ORDER BY tx_count DESC)      AS rnk
    FROM account_weekly_count
),
top5_json AS (
    SELECT 
        week_start,
        to_json(
            collect_list(
                named_struct('account_id', account_id, 'tx_count', tx_count)
            )
        )                                                        AS top_5_accounts_by_count
    FROM ranked_accounts
    WHERE rnk <= 5 
    GROUP BY week_start
)

SELECT 
    wb.week_start,
    wb.days_in_week,
    wb.total_volume,
    wb.transaction_count,

    ROUND(
        (wb.total_volume - lag(wb.total_volume) OVER (ORDER BY wb.week_start)) * 100 
        / lag(wb.total_volume) OVER (ORDER BY wb.week_start), 2
    )                                                           AS wow_volume_change_pct,

    ROUND(
        (wb.transaction_count - lag(wb.transaction_count) OVER (ORDER BY wb.week_start)) * 100 
        / lag(wb.transaction_count) OVER (ORDER BY wb.week_start), 2
    )                                                           AS wow_count_change_pct,

    ROUND(wb.cash_in_volume  * 100.0 / wb.total_volume, 2)       AS type_mix_cash_in_pct,
    ROUND(wb.cash_out_volume * 100.0 / wb.total_volume, 2)       AS type_mix_cash_out_pct,
    ROUND(wb.transfer_volume * 100.0 / wb.total_volume, 2)       AS type_mix_transfer_pct,

    ROUND(wb.cash_out_volume / NULLIF(wb.cash_in_volume, 0), 4)  AS cashout_to_cashin_ratio,

    t5.top_5_accounts_by_count
FROM weekly_base wb 
LEFT JOIN top5_json t5 ON wb.week_start = t5.week_start