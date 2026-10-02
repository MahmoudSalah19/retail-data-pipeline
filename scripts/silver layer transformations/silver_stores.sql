/*
===============================================================================
Silver Transformation: stores
===============================================================================
Purpose:
    Clean bronze.stores, producing one row per store ready for the
    Silver layer.

Data quality issues found in bronze.stores:
    - One exact duplicate row (same id, name, city, and region repeated).
    - No missing/null values found in id, name, city, or region.

Transformations applied:
    - Trim whitespace and lowercase id, name, and city.
    - region is trimmed but NOT lowercased, kept as-is (e.g. "NA", "EMEA")
      to match the region_country_map keys used in the geocoding and
      holidays extraction scripts (extract_from_meteo_api.py). Lowercasing
      it here would break that lookup unless the Python-side keys were
      updated to match.
    - DISTINCT removes the one fully-identical duplicate row; no
      ROW_NUMBER() dedup needed since no rows share an id with differing
      values.
===============================================================================
*/
SELECT DISTINCT
    LOWER(TRIM(id)) AS id,
    LOWER(TRIM(name)) AS name,
    LOWER(TRIM(city)) AS city,
    TRIM(region) AS region
FROM bronze.stores;
