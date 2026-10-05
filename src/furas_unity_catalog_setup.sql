-- ============================================================
-- STEP 1: Create the Bronze schema
-- Purpose:
-- Store/register raw source-level datasets.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS tenderdatabricks.bronze;


-- ============================================================
-- STEP 2: Create the Silver schema
-- Purpose:
-- Store/register cleaned and standardized tender datasets.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS tenderdatabricks.silver;


-- ============================================================
-- STEP 3: Create the Gold schema
-- Purpose:
-- Store business-ready presentation tables for analytics.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS tenderdatabricks.gold;


-- ============================================================
-- STEP 4: Verify the Medallion schemas
-- ============================================================

SHOW SCHEMAS IN tenderdatabricks;


-- ============================================================
-- STEP: Register NUPCO raw Bronze data in Unity Catalog
-- Purpose:
-- Expose the existing raw NUPCO JSON snapshots through
-- Unity Catalog without copying or transforming the data.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.bronze.nupco_raw
USING JSON
OPTIONS (
  path 'abfss://bronze@tenderdatalake11.dfs.core.windows.net/nupco/',
  multiLine 'true',
  recursiveFileLookup 'true'
);

-- ============================================================
-- STEP: Verify the NUPCO Bronze table
-- ============================================================

SELECT
    source,
    ingestion_timestamp,
    record_count,
    pages_scraped,
    source_url
FROM tenderdatabricks.bronze.nupco_raw
ORDER BY ingestion_timestamp;

-- ============================================================
-- STEP: Verify the Bronze table schema
-- ============================================================

DESCRIBE TABLE tenderdatabricks.bronze.nupco_raw;


-- ============================================================
-- STEP: Register STC raw Bronze data in Unity Catalog
-- Purpose:
-- Expose all historical STC JSON snapshots through
-- Unity Catalog without transforming or copying the raw data.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.bronze.stc_raw
USING JSON
OPTIONS (
  path 'abfss://bronze@tenderdatalake11.dfs.core.windows.net/stc/',
  multiLine 'true',
  recursiveFileLookup 'true'
);

-- ============================================================
-- STEP: Verify STC Bronze snapshots
-- ============================================================

SELECT
    source,
    ingestion_timestamp,
    record_count,
    source_url
FROM tenderdatabricks.bronze.stc_raw
ORDER BY ingestion_timestamp;

-- ============================================================
-- STEP: Verify STC Bronze schema
-- ============================================================

DESCRIBE TABLE tenderdatabricks.bronze.stc_raw;

-- ============================================================
-- STEP: Register Etimad raw Bronze data in Unity Catalog
-- Purpose:
-- Expose all historical Etimad JSON records through
-- Unity Catalog while preserving the source-native structure.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.bronze.etimad_raw
USING JSON
OPTIONS (
  path 'abfss://bronze@tenderdatalake11.dfs.core.windows.net/ETIMAD/',
  multiLine 'true',
  recursiveFileLookup 'true'
);

-- ============================================================
-- STEP: Validate Etimad Bronze table
-- Purpose:
-- Confirm that Unity Catalog can access all raw Etimad records.
-- ============================================================

SELECT COUNT(*) AS raw_record_count
FROM tenderdatabricks.bronze.etimad_raw;

-- ============================================================
-- STEP: Verify Etimad Bronze schema
-- ============================================================

DESCRIBE TABLE tenderdatabricks.bronze.etimad_raw;

-- ============================================================
-- STEP: Register CST raw Bronze data in Unity Catalog
-- Purpose:
-- Expose the existing raw CST CSV data through Unity Catalog
-- while preserving its source-level structure.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.bronze.cst_raw
USING CSV
OPTIONS (
    path 'abfss://bronze@tenderdatalake11.dfs.core.windows.net/cst/',
    header 'true',
    inferSchema 'true',
    recursiveFileLookup 'true'
);

-- ============================================================
-- STEP: Validate CST Bronze records
-- ============================================================

SELECT COUNT(*) AS raw_record_count
FROM tenderdatabricks.bronze.cst_raw;

-- ============================================================
-- STEP: Verify CST Bronze schema
-- ============================================================

DESCRIBE TABLE tenderdatabricks.bronze.cst_raw;

-- ============================================================
-- STEP: Register Tanafos raw Bronze data in Unity Catalog
-- Purpose:
-- Expose the existing raw Tanafos JSON data through
-- Unity Catalog while preserving its source-native structure.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.bronze.tanafos_raw
USING JSON
OPTIONS (
    path 'abfss://bronze@tenderdatalake11.dfs.core.windows.net/Tanafos/',
    multiLine 'true',
    recursiveFileLookup 'true'
);

-- ============================================================
-- STEP: Validate Tanafos Bronze records
-- ============================================================

SELECT COUNT(*) AS raw_record_count
FROM tenderdatabricks.bronze.tanafos_raw;

-- ============================================================
-- STEP: Verify Tanafos Bronze schema
-- ============================================================

DESCRIBE TABLE tenderdatabricks.bronze.tanafos_raw;

-- ============================================================
-- STEP: Register TAQEEM raw Bronze data in Unity Catalog
-- Purpose:
-- Expose the existing raw TAQEEM JSON data through
-- Unity Catalog while preserving its source-native structure.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.bronze.taqeem_raw
USING JSON
OPTIONS (
    path 'abfss://bronze@tenderdatalake11.dfs.core.windows.net/TAQEEM/',
    multiLine 'true',
    recursiveFileLookup 'true'
);

-- ============================================================
-- STEP: Validate TAQEEM Bronze records
-- ============================================================

SELECT COUNT(*) AS raw_record_count
FROM tenderdatabricks.bronze.taqeem_raw;

-- ============================================================
-- STEP: Verify TAQEEM Bronze schema
-- ============================================================

DESCRIBE TABLE tenderdatabricks.bronze.taqeem_raw;

-- ============================================================
-- STEP: Register TAHAKOM raw Bronze data in Unity Catalog
-- Purpose:
-- Expose the existing raw TAHAKOM JSON data through
-- Unity Catalog while preserving its source-native structure.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.bronze.tahakom_raw
USING JSON
OPTIONS (
    path 'abfss://bronze@tenderdatalake11.dfs.core.windows.net/TAHAKOM/',
    multiLine 'true',
    recursiveFileLookup 'true'
);

-- ============================================================
-- STEP: Validate TAHAKOM Bronze records
-- ============================================================

SELECT COUNT(*) AS raw_record_count
FROM tenderdatabricks.bronze.tahakom_raw;

-- ============================================================
-- STEP: Verify TAHAKOM Bronze schema
-- ============================================================

DESCRIBE TABLE tenderdatabricks.bronze.tahakom_raw;

-- ============================================================
-- STEP: Register GEO raw Bronze data in Unity Catalog
-- Purpose:
-- Register the original GEO CSV without parsing or
-- transforming the embedded tender content.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.bronze.geo_raw
USING CSV
OPTIONS (
    path 'abfss://bronze@tenderdatalake11.dfs.core.windows.net/GEO/',
    header 'true',
    inferSchema 'true',
    recursiveFileLookup 'true'
);

-- ============================================================
-- STEP: Validate GEO Bronze records
-- Purpose:
-- Confirm that all raw CSV rows are accessible through
-- Unity Catalog.
-- ============================================================

SELECT COUNT(*) AS raw_record_count
FROM tenderdatabricks.bronze.geo_raw;

-- ============================================================
-- STEP: Verify GEO Bronze schema
-- ============================================================

DESCRIBE TABLE tenderdatabricks.bronze.geo_raw;

-- ============================================================
-- STEP: Register SAR raw Bronze data in Unity Catalog
-- Purpose:
-- Register only the original SAR tender CSV while preserving
-- its source-native structure and excluding the Python file.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.bronze.sar_raw
USING CSV
OPTIONS (
    path 'abfss://bronze@tenderdatalake11.dfs.core.windows.net/SAR/2026-09-20/sar_tenders.csv',
    header 'true',
    inferSchema 'true'
);

-- ============================================================
-- STEP: Validate SAR Bronze records
-- Purpose:
-- Confirm that the raw SAR records are accessible through
-- Unity Catalog.
-- ============================================================

SELECT COUNT(*) AS raw_record_count
FROM tenderdatabricks.bronze.sar_raw;

-- ============================================================
-- STEP: Verify SAR Bronze schema
-- Purpose:
-- Confirm that the source-native SAR columns are preserved.
-- ============================================================

DESCRIBE TABLE tenderdatabricks.bronze.sar_raw;

-- ============================================================
-- STEP: Verify all Bronze Unity Catalog tables
-- Purpose:
-- Review the registered Bronze sources and identify whether
-- any remaining source still needs to be added.
-- ============================================================

SHOW TABLES IN tenderdatabricks.bronze;






-- ============================================================
-- STEP: Register NUPCO Silver table in Unity Catalog
-- Purpose:
-- Register the existing standardized NUPCO Delta dataset
-- without copying or rewriting the Silver data.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.nupco
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders/nupco';

-- ============================================================
-- STEP: Validate NUPCO Silver Catalog table
-- Purpose:
-- Confirm that the registered Catalog table points to the
-- existing standardized Silver Delta dataset.
-- ============================================================

SELECT COUNT(*) AS silver_record_count
FROM tenderdatabricks.silver.nupco;

-- ============================================================
-- STEP: Verify NUPCO Silver schema
-- Purpose:
-- Confirm that the standardized data types were preserved
-- after registration in Unity Catalog.
-- ============================================================

DESCRIBE TABLE tenderdatabricks.silver.nupco;

SELECT *
FROM tenderdatabricks.silver.nupco;


-- ============================================================
-- STEP: Register remaining source-specific Silver tables
-- Purpose:
-- Register the existing standardized Delta datasets in
-- Unity Catalog without copying or rewriting the data.
-- ============================================================

-- CST
CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.cst
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders/cst';

-- ETIMAD
CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.etimad
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders/etimad';

-- FORSAH
CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.forsah
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders/forsah';

-- GEO
CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.geo_resources
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders/geo_resources';

-- SAR
CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.sar
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders/sar';

-- STC
CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.stc
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders/stc';

-- TAHAKOM
CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.tahakom
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders/tahakom';

-- TANAFOS
CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.tanafos
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders/tanafos';

-- TAQEEM
CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.taqeem
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders/taqeem';

-- ============================================================
-- STEP: Verify source-specific Silver Catalog tables
-- Purpose:
-- Confirm that all 10 standardized source datasets are
-- registered successfully in the Silver schema.
-- ============================================================

SHOW TABLES IN tenderdatabricks.silver;


-- ============================================================
-- STEP: Register unified Silver tender table in Unity Catalog
-- Purpose:
-- Register the existing unified and standardized Silver
-- Delta dataset without copying or rewriting the data.
-- ============================================================

CREATE TABLE IF NOT EXISTS tenderdatabricks.silver.tenders_unified
USING DELTA
LOCATION 'abfss://silver@tenderdatalake11.dfs.core.windows.net/tenders_unified';

-- ============================================================
-- STEP: Validate unified Silver Catalog table
-- Purpose:
-- Confirm that the Catalog table points to the existing
-- unified Silver dataset.
-- ============================================================

SELECT COUNT(*) AS unified_silver_record_count
FROM tenderdatabricks.silver.tenders_unified;

-- ============================================================
-- STEP: Verify all Silver Catalog tables
-- Purpose:
-- Confirm that the complete Silver layer is now visible
-- and governed through Unity Catalog.
-- ============================================================

SHOW TABLES IN tenderdatabricks.silver;

-- ============================================================
-- STEP: Inspect current Gold Unity Catalog
-- Purpose:
-- Confirm the currently registered Gold presentation tables.
-- ============================================================

SHOW TABLES IN tenderdatabricks.gold;



-- ============================================================
-- STEP: Register Gold star-schema tables in Unity Catalog
-- Purpose:
-- Register the Delta datasets from the physical Gold ADLS
-- container as governed Unity Catalog tables.
-- ============================================================

-- Fact table
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.fact_tenders
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/fact_tenders/';


-- Tender dimension
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.dim_tender
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/dim_tender/';


-- Source dimension
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.dim_source
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/dim_source/';


-- Agency dimension
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.dim_agency
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/dim_agency/';


-- Date dimension
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.dim_date
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/dim_date/';


-- Tender type dimension
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.dim_tender_type
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/dim_tender_type/';


-- Status dimension
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.dim_status
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/dim_status/';


-- Category dimension
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.dim_category
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/dim_category/';


-- Region dimension
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.dim_region
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/dim_region/';


-- Tender-category bridge
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.bridge_tender_category
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/bridge_tender_category/';


-- Tender-region bridge
CREATE TABLE IF NOT EXISTS tenderdatabricks.gold.bridge_tender_region
USING DELTA
LOCATION 'abfss://gold@tenderdatalake11.dfs.core.windows.net/bridge_tender_region/';



-- ============================================================
-- STEP: Verify Gold Catalog tables
-- Purpose:
-- Confirm that all 11 Gold tables are visible in Unity Catalog.
-- ============================================================

SHOW TABLES IN tenderdatabricks.gold;



-- ============================================================
-- STEP: Validate Gold Catalog table record counts
-- Purpose:
-- Confirm that all registered Gold tables are readable and
-- contain the expected presentation-layer data.
-- ============================================================

SELECT 'fact_tenders' AS table_name, COUNT(*) AS row_count
FROM tenderdatabricks.gold.fact_tenders

UNION ALL
SELECT 'dim_tender', COUNT(*)
FROM tenderdatabricks.gold.dim_tender

UNION ALL
SELECT 'dim_source', COUNT(*)
FROM tenderdatabricks.gold.dim_source

UNION ALL
SELECT 'dim_agency', COUNT(*)
FROM tenderdatabricks.gold.dim_agency

UNION ALL
SELECT 'dim_date', COUNT(*)
FROM tenderdatabricks.gold.dim_date

UNION ALL
SELECT 'dim_tender_type', COUNT(*)
FROM tenderdatabricks.gold.dim_tender_type

UNION ALL
SELECT 'dim_status', COUNT(*)
FROM tenderdatabricks.gold.dim_status

UNION ALL
SELECT 'dim_category', COUNT(*)
FROM tenderdatabricks.gold.dim_category

UNION ALL
SELECT 'dim_region', COUNT(*)
FROM tenderdatabricks.gold.dim_region

UNION ALL
SELECT 'bridge_tender_category', COUNT(*)
FROM tenderdatabricks.gold.bridge_tender_category

UNION ALL
SELECT 'bridge_tender_region', COUNT(*)
FROM tenderdatabricks.gold.bridge_tender_region;



DESCRIBE TABLE tenderdatabricks.gold.fact_tenders;

-- ============================================================
-- STEP: Add metadata comments to fact_tenders
-- Purpose:
-- Document the grain, foreign keys, and analytical measures
-- directly in Unity Catalog.
-- ============================================================

COMMENT ON TABLE tenderdatabricks.gold.fact_tenders IS
'Central Gold fact table. Grain: one row per technology-relevant tender. Contains dimension foreign keys and numeric measures for analytics.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN tender_key
COMMENT 'Unique identifier for each tender and the grain of the fact table.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN source_key
COMMENT 'Foreign key referencing dim_source.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN agency_key
COMMENT 'Foreign key referencing dim_agency.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN tender_type_key
COMMENT 'Foreign key referencing dim_tender_type.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN status_key
COMMENT 'Foreign key referencing dim_status.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN publish_date_key
COMMENT 'Foreign key referencing dim_date for the tender publication date.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN closing_date_key
COMMENT 'Foreign key referencing dim_date for the tender closing date.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN opening_date_key
COMMENT 'Foreign key referencing dim_date for the tender opening date.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN tender_count
COMMENT 'Additive measure with value 1 for each tender; used to count tenders.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN estimated_value_min
COMMENT 'Minimum estimated monetary value of the tender when available.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN estimated_value_max
COMMENT 'Maximum estimated monetary value of the tender when available.';

ALTER TABLE tenderdatabricks.gold.fact_tenders
ALTER COLUMN document_price
COMMENT 'Tender document price when available.';




-- ============================================================
-- STEP: Add metadata comments to dim_tender
-- Purpose:
-- Document the descriptive tender dimension in Unity Catalog.
-- ============================================================

COMMENT ON TABLE tenderdatabricks.gold.dim_tender IS
'Descriptive tender dimension containing one row per technology-relevant tender and its business attributes.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN tender_key
COMMENT 'Unique identifier for the tender; connects to fact_tenders.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN source_tender_id
COMMENT 'Tender identifier provided by the original source system.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN reference_number
COMMENT 'Reference number associated with the tender.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN tender_name
COMMENT 'Original tender name collected from the source.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN tender_name_ar
COMMENT 'Arabic tender name when available.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN tender_name_en
COMMENT 'English tender name when available.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN description
COMMENT 'Detailed description of the tender when available.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN is_tech
COMMENT 'Indicates whether the tender is classified as technology-related.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN tech_classification_reason
COMMENT 'Reason or method used to identify the tender as technology-related.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN currency
COMMENT 'Currency associated with the tender financial values when available.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN tender_url
COMMENT 'Source URL for accessing the original tender.';

ALTER TABLE tenderdatabricks.gold.dim_tender
ALTER COLUMN ingestion_timestamp
COMMENT 'Timestamp indicating when the tender data was ingested into the pipeline.';

DESCRIBE TABLE tenderdatabricks.gold.dim_tender;


-- ============================================================
-- STEP: Add metadata comments to remaining Gold tables
-- Purpose:
-- Document the role of each dimension and bridge table.
-- ============================================================

COMMENT ON TABLE tenderdatabricks.gold.dim_source IS
'Source dimension containing the procurement portal or platform from which each tender was collected.';

COMMENT ON TABLE tenderdatabricks.gold.dim_agency IS
'Agency dimension containing organizations or entities associated with tenders.';

COMMENT ON TABLE tenderdatabricks.gold.dim_date IS
'Date dimension used for tender publication, closing, and opening date analysis.';

COMMENT ON TABLE tenderdatabricks.gold.dim_tender_type IS
'Tender type dimension containing standardized tender and procurement types.';

COMMENT ON TABLE tenderdatabricks.gold.dim_status IS
'Status dimension containing standardized tender status and opportunity state values.';

COMMENT ON TABLE tenderdatabricks.gold.dim_category IS
'Category dimension containing standardized categories associated with tenders.';

COMMENT ON TABLE tenderdatabricks.gold.dim_region IS
'Region dimension containing geographic regions associated with tenders.';

COMMENT ON TABLE tenderdatabricks.gold.bridge_tender_category IS
'Bridge table supporting the many-to-many relationship between tenders and categories.';

COMMENT ON TABLE tenderdatabricks.gold.bridge_tender_region IS
'Bridge table supporting the many-to-many relationship between tenders and regions.';
