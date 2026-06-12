CREATE OR REPLACE TABLE dim_account AS 
SELECT 
    account_id,
    MAX(isOrig) AS is_origin_account,
    MAX(isDest) AS is_destination_account

FROM (
    SELECT 
        nameOrig AS account_id, 1 AS isOrig, 0 AS isDest
        FROM transactions_with_dates
        UNION ALL 
    SELECT 
        nameDest AS account_id, 0 AS isOrig, 1 AS isDest
        FROM transactions_with_dates
)
GROUP BY account_id