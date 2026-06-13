CREATE OR REPLACE TABLE fact_daily_transactions AS
SELECT
    monotonically_increasing_id() AS trans_id,
    simulated_date AS date,
    nameOrig AS account_orig,
    nameDest AS account_dest,
    amount,
    type AS transaction_type,
    oldbalanceOrg AS bal_before_transaction,
    newbalanceOrig AS bal_after_transaction,
    isFraud AS is_fraud,
    isFlaggedFraud AS is_flagged_fraud
FROM
    transactions_with_dates