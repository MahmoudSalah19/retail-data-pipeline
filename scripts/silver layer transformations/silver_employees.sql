/*
===============================================================================
Silver Transformation: employees
===============================================================================
Purpose:
    Clean bronze.employees and recover missing data using
    sales_transactions, producing one row per employee_id ready for the
    Silver layer.

Data quality issues found in bronze.employees:
    - Some rows have a valid employee_id but a missing store_id.
    - sales_transactions references employee_ids that don't exist in
      employees at all (no full_name or store_id on file).

Recovery strategy:
    1. Missing store_id (valid employee_id present): recovered from
       sales_transactions, using employee_id as the join key (a genuine
       unique identifier, unlike price in the products table).
    2. employee_ids present in sales_transactions but missing from
       employees entirely: added with full_name explicitly labeled
       'unknown', since no other source of that information exists.
    3. Any employee_id or store_id still unresolved after recovery
       defaults to 'unknown' rather than being left NULL.

Approach:
    - sales_employee: one row per employee_id from sales_transactions,
      aggregating to a single store_id per employee via MAX() (a simple,
      deterministic choice since only one representative value is needed).
    - existing_employees: employees present in bronze.employees, with
      missing store_id backfilled from sales_employee.
    - missing_employees: employee_ids found in sales_employee but absent
      from existing_employees, identified via a LEFT JOIN / IS NULL
      anti-join (avoids the NULL-handling pitfall of NOT IN).
===============================================================================
*/
WITH sales_employee AS (
    SELECT
        LOWER(TRIM(employee_id)) AS employee_id,
        MAX(LOWER(TRIM(store_id))) AS store_id
    FROM bronze.sales_transactions
    WHERE employee_id IS NOT NULL
    GROUP BY LOWER(TRIM(employee_id))
),

existing_employees AS (
    SELECT
        LOWER(TRIM(e.employee_id)) AS employee_id,
        COALESCE(
            LOWER(TRIM(e.full_name)),
            'unknown'
        ) AS full_name,
        COALESCE(
            LOWER(TRIM(e.store_id)),
            s.store_id,
            'unknown'
        ) AS store_id
    FROM bronze.employees e
    LEFT JOIN sales_employee s
        ON LOWER(TRIM(e.employee_id)) = s.employee_id
    WHERE e.employee_id IS NOT NULL
),

missing_employees AS (
    SELECT
        s.employee_id,
        'unknown' AS full_name,
        COALESCE(s.store_id, 'unknown') AS store_id
    FROM sales_employee s
    LEFT JOIN existing_employees e
        ON s.employee_id = e.employee_id
    WHERE e.employee_id IS NULL
)

SELECT
    employee_id,
    full_name,
    store_id
FROM existing_employees

UNION

SELECT
    employee_id,
    full_name,
    store_id
FROM missing_employees;
