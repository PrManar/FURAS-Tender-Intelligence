-- ============================================================
-- STEP: Inspect Gold tables
-- Purpose:
-- Preview the actual records stored in each Gold table.
-- ============================================================

-- 1. Main fact table
SELECT *
FROM tenderdatabricks.gold.fact_tenders
LIMIT 20;

-- 2. Source dimension
SELECT *
FROM tenderdatabricks.gold.dim_source
ORDER BY source_key;

-- 3. Agency dimension
SELECT *
FROM tenderdatabricks.gold.dim_agency
ORDER BY agency_key;

-- 4. Date dimension
SELECT *
FROM tenderdatabricks.gold.dim_date
ORDER BY date_key
LIMIT 150;

-- 5. Tender type dimension
SELECT *
FROM tenderdatabricks.gold.dim_tender_type
ORDER BY tender_type_key;

-- 6. Status dimension
SELECT *
FROM tenderdatabricks.gold.dim_status
ORDER BY status_key;

-- 7. Category dimension
SELECT *
FROM tenderdatabricks.gold.dim_category
ORDER BY category_key;

-- 8. Region dimension
SELECT *
FROM tenderdatabricks.gold.dim_region
ORDER BY region_key;

-- 9. Tender-category bridge
SELECT *
FROM tenderdatabricks.gold.bridge_tender_category
LIMIT 50;

-- 10. Tender-region bridge
SELECT *
FROM tenderdatabricks.gold.bridge_tender_region
LIMIT 50;


SELECT *
FROM tenderdatabricks.gold.dim_tender
LIMIT 20;


-- ============================================================
-- STEP: Final Gold relationship validation
-- Purpose:
-- Confirm that fact and bridge foreign keys correctly match
-- their corresponding Gold dimensions.
-- ============================================================

SELECT
    -- Main dimensions
    SUM(CASE WHEN s.source_key IS NULL THEN 1 ELSE 0 END)
        AS invalid_source_keys,

    SUM(CASE WHEN a.agency_key IS NULL THEN 1 ELSE 0 END)
        AS invalid_agency_keys,

    SUM(CASE WHEN tt.tender_type_key IS NULL THEN 1 ELSE 0 END)
        AS invalid_tender_type_keys,

    SUM(CASE WHEN st.status_key IS NULL THEN 1 ELSE 0 END)
        AS invalid_status_keys,

    -- Tender dimension
    SUM(CASE WHEN dt.tender_key IS NULL THEN 1 ELSE 0 END)
        AS invalid_tender_keys,

    -- Date roles
    SUM(CASE WHEN pd.date_key IS NULL THEN 1 ELSE 0 END)
        AS invalid_publish_date_keys,

    SUM(CASE WHEN cd.date_key IS NULL THEN 1 ELSE 0 END)
        AS invalid_closing_date_keys,

    SUM(CASE WHEN od.date_key IS NULL THEN 1 ELSE 0 END)
        AS invalid_opening_date_keys

FROM tenderdatabricks.gold.fact_tenders f

LEFT JOIN tenderdatabricks.gold.dim_source s
    ON f.source_key = s.source_key

LEFT JOIN tenderdatabricks.gold.dim_agency a
    ON f.agency_key = a.agency_key

LEFT JOIN tenderdatabricks.gold.dim_tender_type tt
    ON f.tender_type_key = tt.tender_type_key

LEFT JOIN tenderdatabricks.gold.dim_status st
    ON f.status_key = st.status_key

LEFT JOIN tenderdatabricks.gold.dim_tender dt
    ON f.tender_key = dt.tender_key

LEFT JOIN tenderdatabricks.gold.dim_date pd
    ON f.publish_date_key = pd.date_key

LEFT JOIN tenderdatabricks.gold.dim_date cd
    ON f.closing_date_key = cd.date_key

LEFT JOIN tenderdatabricks.gold.dim_date od
    ON f.opening_date_key = od.date_key;


-- ============================================================
-- STEP: Validate Gold bridge-table relationships
-- Purpose:
-- Confirm that category and region bridge records reference
-- valid tenders and valid dimension members.
-- ============================================================

SELECT
    'category_bridge' AS bridge_name,

    SUM(CASE WHEN f.tender_key IS NULL THEN 1 ELSE 0 END)
        AS invalid_tender_keys,

    SUM(CASE WHEN c.category_key IS NULL THEN 1 ELSE 0 END)
        AS invalid_dimension_keys

FROM tenderdatabricks.gold.bridge_tender_category b

LEFT JOIN tenderdatabricks.gold.fact_tenders f
    ON b.tender_key = f.tender_key

LEFT JOIN tenderdatabricks.gold.dim_category c
    ON b.category_key = c.category_key

UNION ALL

SELECT
    'region_bridge',

    SUM(CASE WHEN f.tender_key IS NULL THEN 1 ELSE 0 END),

    SUM(CASE WHEN r.region_key IS NULL THEN 1 ELSE 0 END)

FROM tenderdatabricks.gold.bridge_tender_region b

LEFT JOIN tenderdatabricks.gold.fact_tenders f
    ON b.tender_key = f.tender_key

LEFT JOIN tenderdatabricks.gold.dim_region r
    ON b.region_key = r.region_key;