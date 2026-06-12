CREATE OR REPLACE TABLE dim_date AS
SELECT
    simulated_date AS date,
    DAY(simulated_date) AS day_num,
    DAYOFWEEK(simulated_date) AS day_num_in_week,
    DATE_FORMAT(simulated_date, 'EEEE') AS day_name,
    DATE_TRUNC('week', simulated_date) AS week_start
FROM (
    SELECT DISTINCT simulated_date
    FROM transactions_with_dates
)
ORDER BY date