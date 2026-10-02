/*
===============================================================================
Silver Transformation: products
===============================================================================
Purpose:
    Clean bronze.products and recover missing data using order_lines,
    producing one row per product_id ready for the Silver layer.

Data quality issues found in bronze.products:
    - Some rows have a valid id but a missing unit_price.
    - 2 rows have a missing id but valid name/category/unit_price.
    - order_lines references 2 product_ids that don't exist in products
      at all (no name, category, or price on file).

Recovery strategy:
    1. Missing unit_price (valid id present): recovered via a safe join on
       id = order_lines.product_id, since id is a genuine unique key.
    2. Missing id (valid price present): recovered via a join on
       unit_price = order_lines.unit_price.
       NOTE: price is NOT a reliable join key in general - two different
       products could share a price in a real-world dataset. This join is
       used here ONLY because it was explicitly verified that every price
       in this specific dataset is unique per product, in both the
       products and order_lines tables (checked manually before writing
       this query). This approach would need to be re-validated, or
       dropped in favor of a proper business key, if the source data
       ever changes.
    3. Products missing entirely from bronze.products: added using
       order_lines as the only available source, with name and category
       explicitly labeled 'unknown' since no other information exists.

Deduplication:
    Both recovery steps use ROW_NUMBER() partitioned by id to guarantee
    exactly one row per product, in case of multiple matching order_lines.
===============================================================================
*/
WITH resolved_products AS (
    -- Step 1: products with a valid id; recover missing unit_price via id join
    SELECT id, name, category, unit_price
    FROM (
        SELECT 
            LOWER(TRIM(p.id)) AS id,
            COALESCE(LOWER(TRIM(p.name)), 'unknown') AS name,
            COALESCE(LOWER(TRIM(p.category)), 'unknown') AS category,
            CAST(COALESCE(TRIM(p.unit_price), TRIM(o.unit_price)) AS FLOAT) AS unit_price,
            ROW_NUMBER() OVER (
                PARTITION BY LOWER(TRIM(p.id))
                ORDER BY COALESCE(LOWER(TRIM(p.name)), 'unknown') DESC,
                         COALESCE(LOWER(TRIM(p.category)), 'unknown') DESC,
                         CAST(COALESCE(TRIM(p.unit_price), TRIM(o.unit_price)) AS FLOAT) DESC
            ) AS flag
        FROM bronze.products p
        LEFT JOIN bronze.order_lines o ON LOWER(TRIM(p.id)) = LOWER(TRIM(o.product_id))
        WHERE p.id IS NOT NULL
    ) AS sub
    WHERE flag = 1

    UNION

    -- Step 2: products with a missing id; recover id via price join.
    -- Safe here only because price is confirmed unique per product
    -- in this specific dataset (see note above).
    SELECT id, name, category, unit_price
    FROM (
        SELECT 
            LOWER(TRIM(COALESCE(p.id, o.product_id))) AS id,
            LOWER(TRIM(p.name)) AS name,
            LOWER(TRIM(p.category)) AS category,
            CAST(TRIM(p.unit_price) AS FLOAT) AS unit_price,
            ROW_NUMBER() OVER (
                PARTITION BY LOWER(TRIM(COALESCE(p.id, o.product_id)))
                ORDER BY  LOWER(TRIM(p.name)) DESC,
                          LOWER(TRIM(p.category)) DESC,
                          CAST(TRIM(p.unit_price) AS FLOAT) DESC
            ) AS flag
        FROM bronze.products p
        LEFT JOIN bronze.order_lines o ON TRIM(p.unit_price) = TRIM(o.unit_price)
        WHERE p.id IS NULL
    ) AS sub1
    WHERE flag = 1 AND id IS NOT NULL
)

-- Step 3: products referenced in order_lines but absent from products
-- entirely; name/category are genuinely unknown, so labeled explicitly.
SELECT id, name, category, unit_price
FROM resolved_products

UNION

SELECT DISTINCT
    LOWER(TRIM(o.product_id)) AS id,
    'unknown' AS name,
    'unknown' AS category,
    CAST(TRIM(o.unit_price) AS FLOAT) AS unit_price
FROM bronze.order_lines o
WHERE o.product_id IS NOT NULL
  AND o.unit_price IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM resolved_products r WHERE r.id = LOWER(TRIM(o.product_id))
  );
