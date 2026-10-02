/*
===============================================================================
Silver Transformation: customers
===============================================================================
Purpose:
    Clean and deduplicate bronze.customers, producing one row per
    customer_id ready for the Silver layer.

Transformations applied:
    - Trim whitespace and lowercase customer_id and full_name.
    - Missing full_name -> 'unknown'.
    - Drop rows with a missing customer_id (unusable as the join/dedup key).
    - Deduplicate on customer_id: where multiple rows share the same
      customer_id, keep one deterministic row per group (tie broken by
      full_name descending, so NULLs sort last).
===============================================================================
*/
SELECT 
    LOWER(TRIM(customer_id)) AS customer_id,
    CASE
        WHEN full_name IS NULL THEN 'unknown' 
        ELSE LOWER(TRIM(full_name)) 
    END AS full_name
FROM (
    SELECT 
        customer_id,
        full_name,
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(TRIM(customer_id)) 
            ORDER BY LOWER(TRIM(full_name)) DESC
        ) AS flag
    FROM bronze.customers
    WHERE customer_id IS NOT NULL
) AS sub
WHERE flag = 1;
