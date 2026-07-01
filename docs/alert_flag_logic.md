# Alert Flag Logic

This document explains the reasoning behind each of the four triggers in `alert_flags`: why each condition was defined the way it was, what threshold was chosen and why, and what the trigger actually returned when run against the PaySim dataset.

All four triggers are built as plain SQL rules, not models. Every flag that fires can be traced back to a specific account, amount, and date without needing to interpret any model output.

## Trigger 1: Transaction Spike

**Condition:** A single account makes more than 3x its own 30 day average transaction count within a 24 hour window.

**Why this condition.** A fixed global threshold (for example, "flag any account with more than 10 transactions in a day") treats all accounts the same way, which doesn't hold up in practice. A high-frequency account making 50 transactions a day is behaving normally. The same volume from an account that usually makes 2 transactions a day is a real anomaly. Using each account's own baseline means the trigger scales to actual behavior instead of applying one cutoff across the whole dataset.

**Why 3x.** A 2x threshold would produce too many false positives from normal day-to-day variation. A 5x threshold would only catch extreme cases. 3x is the standard starting point used in behavioral anomaly detection: high enough to indicate a real deviation, low enough to avoid noise.

**Validated result:** 0 rows. PaySim's transaction generation logic caps individual accounts at a maximum of 2 transactions per day, which makes the 3x threshold mathematically unreachable. An account averaging 2 transactions a day would need 7 in a single day to trigger it, and the dataset never produces that. This is a limit built into the synthetic data, not a flaw in the trigger logic. The trigger is kept as it is and documented here rather than removed or adjusted, because in a real dataset with genuine behavioral variation it would work as intended.

## Trigger 2: Transfer to Cash-Out Chain

**Condition:** A TRANSFER out of an origin account is followed by a CASH_OUT from the destination account on the same calendar day, where the CASH_OUT amount falls in the top 5% of all CASH_OUT amounts in the dataset.

**Why this pattern.** This is the main money laundering structure present in the PaySim dataset: funds move via transfer to an intermediary account, then get withdrawn as cash right away, before the transaction can be flagged or reversed. Catching it means reconstructing the chain across two separate transaction records linked by account ID and date, rather than judging any single transaction on its own.

**Why the top 5% threshold.** Not every transfer then cash-out sequence is suspicious; the same pattern shows up in normal day-to-day activity at lower amounts. Limiting the flag to the top 5% of CASH_OUT amounts narrows it down to cases where the withdrawal is large enough to suggest deliberate fund extraction rather than routine behavior. The 5% cutoff applies to CASH_OUT amounts specifically, not to the combined chain value, since the cash-out is the actual point of extraction. The computed threshold for this dataset is about $518,000.

**Validated result:** 29 same-day transfer-to-cash-out chains identified. 1 exceeds the $518K threshold and triggers the flag.

## Trigger 3: Daily Fraud Rate Breach

**Condition:** The daily `isFraud` rate goes above 1% of total transactions for that day.

**Why 1%.** Under normal conditions in the PaySim dataset, the fraud rate sits between 0.1% and 0.3% on most days. A breach of 1% in a single day points to either a fraud wave hitting many accounts at once or a monitoring system failure, and both cases call for immediate investigation regardless of the cause.

**Validated result:** Fires on 11 of 31 days. Day 31 stands out: 100% of its 274 transactions are flagged as fraudulent, which turns out to be an artifact of how PaySim generates its final day rather than a real fraud event. This is kept in the output on purpose; filtering it out would mean the trigger quietly ignores a condition it was built to catch. In a production setting, a day-31 style event would need human review to figure out whether it reflects a real incident or a data pipeline issue, which is exactly the right outcome for an emergency alert system.

## Trigger 4: Volume Collapse

**Condition:** Total daily transaction volume drops more than 40% compared to the same day of the previous week.

**Why same-day-last-week instead of yesterday.** Transaction volume follows a natural weekly cycle; weekday volumes differ from weekend volumes in predictable ways. Comparing today against yesterday would set off false alerts every weekend as volume dips below a weekday baseline. Comparing this Tuesday against last Tuesday removes that noise and isolates real drops that aren't explained by the normal weekly pattern.

**Why 40%.** Day-to-day variation within a normal week stays well below 40%. A drop that large against the same weekday baseline is big enough to point to either a real business disruption or a pipeline failure upstream, both of which need immediate attention.

**Validated result:** Fires on 10 of 31 days. This reflects a genuine tapering of transaction activity in the second half of the PaySim dataset, where volume decreases gradually instead of holding a stable baseline throughout. This is a known property of the synthetic data and is documented as such rather than treated as a trigger malfunction.

## `alert_flags` Table

All four triggers write their boolean outputs to a single `alert_flags` table, one row per day, covering all 31 days in the dataset.

| Column | Type | Description |
|---|---|---|
| flag_date | DATE | Date the flags were evaluated against |
| flag_transaction_spike | BOOLEAN | Trigger 1 result |
| flag_chain_attack | BOOLEAN | Trigger 2 result |
| flag_fraudulent_activity | BOOLEAN | Trigger 3 result |
| flag_volume_collapse | BOOLEAN | Trigger 4 result |
| any_flag_active | BOOLEAN | TRUE if any of the above is TRUE |

Across 31 days, `any_flag_active` is TRUE on 15 days.
