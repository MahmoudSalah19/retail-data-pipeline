/*
===============================================================================
Silver Transformation: loyalty_program
===============================================================================
Purpose:
    Clean and deduplicate bronze.loyalty_program, producing one row per
    customer_id ready for the Silver layer.

Transformations applied:
    - Trim whitespace and lowercase loyalty_id, customer_id, and tier.
    - Missing loyalty_id or tier -> 'unknown'.
    - Missing points -> 0 (represents a customer with no recorded point
      activity, not a data error).
    - Drop rows with a missing customer_id (unusable as the join/dedup key).
    - Deduplicate on customer_id: where multiple rows share the same
      customer_id, keep one deterministic row per group (ties broken by
      loyalty_id, tier, then points, all descending so NULLs sort last).
===============================================================================
*/
SELECT
    ISNULL(LOWER(TRIM(loyalty_id)), 'unknown') AS loyalty_id,
    LOWER(TRIM(customer_id)) AS customer_id,
    ISNULL(LOWER(TRIM(tier)), 'unknown') AS tier,
    CASE
        WHEN points IS NULL THEN 0
        ELSE CAST(points AS FLOAT)
    END AS points
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(TRIM(customer_id))
            ORDER BY LOWER(TRIM(loyalty_id)) DESC, LOWER(TRIM(tier)) DESC, TRIM(points) DESC
        ) AS flag
    FROM bronze.loyalty_program
    WHERE customer_id IS NOT NULL
) AS sub1
WHERE flag = 1;
