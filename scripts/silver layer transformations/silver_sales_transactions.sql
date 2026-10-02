/*
===============================================================================
Silver Transformation: sales_transactions
===============================================================================
Purpose:
    Clean bronze.sales_transactions, producing one row per transaction_id
    ready for the Silver layer.

Business reasoning - which columns can tolerate missing data:
    - transaction_id, date, total_amount: MUST exist. Without an id the
      row has no identity to reference; without a date the transaction
      can't be placed in time or matched to holiday/weather enrichment;
      without an amount, revenue totals would be silently wrong whether
      left NULL (excluded from SUM) or defaulted to 0 (understated).
      Rows missing any of these three are dropped entirely.
    - customer_id, store_id, employee_id, payment_method: soft. A
      missing value here means "we don't know who/where/how," but the
      sale itself is still valid and still counts toward revenue -
      comparable to an anonymous walk-in customer. Defaulted to
      'anonymous' (customer_id) or 'unknown' (the rest) rather than
      dropped.
    - promotion_id: missing here is a different KIND of value, not just
      missing data - it means "no promotion was applied," not "unknown."
      Defaulted to 'none' to reflect that distinction accurately.

Deduplication:
    ROW_NUMBER() partitioned by transaction_id (the primary key) guards
    against duplicate transaction_ids with differing data, which a plain
    DISTINCT would not catch. Ties broken by date, customer_id, store_id,
    employee_id, and payment_method, all descending, so NULLs sort last.
===============================================================================
*/
SELECT
    LOWER(TRIM(transaction_id)) AS transaction_id,
    TRIM(date) AS date,
    CASE WHEN customer_id IS NULL THEN 'anonymous' ELSE LOWER(TRIM(customer_id)) END AS customer_id,
    CASE WHEN store_id IS NULL THEN 'unknown' ELSE LOWER(TRIM(store_id)) END AS store_id,
    CASE WHEN employee_id IS NULL THEN 'unknown' ELSE LOWER(TRIM(employee_id)) END AS employee_id,
    CASE WHEN promotion_id IS NULL THEN 'none' ELSE LOWER(TRIM(promotion_id)) END AS promotion_id,
    CASE WHEN payment_method IS NULL THEN 'unknown' ELSE LOWER(TRIM(payment_method)) END AS payment_method,
    ROUND(CAST(TRIM(total_amount) AS FLOAT), 2) AS total_amount
FROM (
    SELECT 
        transaction_id,
        date,
        customer_id,
        store_id,
        employee_id,
        promotion_id,
        payment_method,
        total_amount,
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(TRIM(transaction_id))
            ORDER BY TRIM(date) DESC, LOWER(TRIM(customer_id)) DESC, LOWER(TRIM(store_id)) DESC, 
                     LOWER(TRIM(employee_id)) DESC, LOWER(TRIM(payment_method)) DESC
        ) AS flag
    FROM bronze.sales_transactions
    WHERE transaction_id IS NOT NULL AND date IS NOT NULL AND total_amount IS NOT NULL
) AS subquery
WHERE flag = 1;
