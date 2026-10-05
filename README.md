# FURAS -- Saudi Tenders Intelligence Platform


## 1. Project Summary

**FURAS (فُرص)** is a Saudi tender intelligence platform that collects
tender and procurement opportunities from multiple sources, standardizes
them, and prepares them for analytics and opportunity exploration.

The main data engineering pipeline follows the **Medallion
Architecture**:

**Data Sources → Bronze → Silver → Gold → Databricks SQL Warehouse →
Power BI**

-   **Bronze:** Preserves raw/source-level tender data.
-   **Silver:** Cleans, standardizes, validates, deduplicates, and
    consolidates tender data into a unified structure.
-   **Gold:** Provides analytics-ready dimensional tables for reporting.
-   **Power BI:** Consumes the Gold layer through Databricks SQL
    Warehouse.

The Gold model contains **11 tables: one fact table, eight dimension
tables, and two bridge tables**. The project also includes the **FURAS
Smart Assistant**, a Streamlit-based RAG assistant that supports tender
inquiry and multilingual interaction.

## 2. Requirements

### Main Data Engineering Pipeline

-   Azure Databricks workspace
-   Azure Data Lake Storage Gen2 (ADLS Gen2)
-   Delta Lake
-   Unity Catalog
-   Python / PySpark
-   SQL
-   Databricks SQL Warehouse
-   Power BI Desktop
-   Databricks workflow


### Smart Assistant

-   Python 3.9+
-   Streamlit
-   Databricks workspace with the services required by the assistant
-   Databricks Vector Search
-   Access to the configured Llama 3.3 70B Instruct model endpoint
-   Snowflake access where required by the submitted Smart Assistant/RAG
    pipeline
-   Valid Databricks authentication for the application

Python package dependencies are listed in:

``` text
requirements.txt
```

## 3. Installation

Install the Python dependencies from the project root:

``` bash
pip install -r requirements.txt
```

The data engineering notebooks depend on Azure/Databricks cloud
infrastructure and are not intended to run as standalone local notebooks
without equivalent storage, catalog, and access configuration.

For the Smart Assistant, ensure that the required Streamlit and
Databricks configuration is available before launching the application.

## 4. Run the Project

### A. Data Engineering Pipeline

#### Step 1 -- Configure Storage

Confirm that the Bronze, Silver, and Gold storage locations are
available and that Databricks has the required permissions.

Typical ADLS structure:

``` text
ADLS Gen2
├── bronze/
├── silver/
└── gold/
```

Do not place storage keys, passwords, personal access tokens, or other
secrets directly in notebooks or this README.

#### Step 2 -- Configure Unity Catalog

The project catalog follows the Medallion structure:

``` text
tenderdatabricks
├── bronze
├── silver
└── gold
```

Run the submitted Unity Catalog setup SQL where required to register the
project schemas and tables.

#### Step 3 -- Run Source Ingestion

Run the source-specific ingestion code/notebooks included in `02_src/`.
The project integrates multiple Saudi tender and procurement sources,
with separate ingestion logic because each source exposes data
differently.

#### Step 4 -- Run Bronze to Silver

Run the submitted Bronze-to-Silver processing notebook.

This stage:

-   Reads raw Bronze data
-   Cleans and standardizes source fields
-   Normalizes data types
-   Handles missing values
-   Identifies/handles duplicate records
-   Consolidates sources into the unified Silver tender dataset

The unified Silver dataset contains **24 fields**.

#### Step 5 -- Run Silver to Gold

Run the submitted Silver-to-Gold processing notebook.

This stage creates the analytics-ready Gold dimensional model:

``` text
fact_tenders
dim_tender
dim_source
dim_agency
dim_date
dim_tender_type
dim_status
dim_category
dim_region
bridge_tender_category
bridge_tender_region
```

`fact_tenders` is the central fact table. The two bridge tables support
the many-to-many relationships between tenders and categories, and
between tenders and regions.

#### Step 6 -- Validate Gold

Run the submitted Gold validation SQL and confirm that:

-   Gold tables are registered and readable
-   Tender keys are valid
-   Dimension relationships are valid
-   Bridge-table relationships are valid
-   No unexpected invalid foreign-key relationships remain

#### Step 7 -- Connect Power BI

In Power BI Desktop, use the **Azure Databricks** connector and connect
through the project's Databricks SQL Warehouse.

The Power BI user requires:

-   Permission to use the SQL Warehouse
-   `USE CATALOG` on the project catalog
-   `USE SCHEMA` on the Gold schema
-   `SELECT` access to the Gold tables

Use the **Server Hostname** and **HTTP Path** from the SQL Warehouse
connection details. Each teammate should authenticate with their own
authorized account.

### B. FURAS Smart Assistant

The project also includes a Streamlit-based Smart Assistant with RAG
functionality. The submitted assistant files include the Streamlit
application and the Databricks/RAG processing code.

To launch the Streamlit application locally, use the application path
included in `src/`, for example:

``` bash
streamlit run src/app.py
```

The Smart Assistant supports Arabic and English interaction and uses
retrieved tender information to answer tender-related questions. The
submitted assistant documentation also includes retrieval and guardrail
testing evidence.

## 5. API Keys & Environment Variables


For components that require Databricks authentication, configure
credentials securely in the environment used to run the application. The
Smart Assistant documentation uses Streamlit secrets in the following
form:

``` toml
DATABRICKS_HOST = "https://<your-databricks-workspace-url>"
DATABRICKS_TOKEN = "<your-databricks-token>"
```


## 6. Known Issues

-   The data engineering notebooks depend on configured Azure and
    Databricks resources and cannot run unchanged in an unrelated local
    environment.
-   Storage paths, Unity Catalog objects, and required permissions must
    be configured before execution.
-   Source websites and their data-access methods may change over time
    and may require updates to individual ingestion logic.
-   Some tender records contain missing or incomplete source fields.
-   Power BI date modeling requires appropriate handling because
    `fact_tenders` contains publication, closing, and opening date keys.
-   User permissions differ by role; teammates may require catalog,
    schema, table, storage, or SQL Warehouse access before running all
    components.
-   The Smart Assistant requires its configured Databricks/RAG services
    and credentials to be available.
-   External service availability and source-system changes can affect
    ingestion or assistant functionality.


## Main Technologies

-   Azure Data Lake Storage Gen2
-   Azure Databricks
-   Apache Spark / PySpark
-   Delta Lake
-   Unity Catalog
-   Databricks SQL Warehouse
-   Power BI
-   Python
-   SQL
-   Streamlit
-   Databricks Vector Search
-   Llama 3.3 70B Instruct


## Security Notes

-   Never commit passwords, access tokens, API keys, or storage keys.
-   Each teammate should use their own account.
-   Grant only the permissions required for each role.
-   Power BI consumers normally need read access to the Gold
    presentation layer rather than administrative privileges.

## Team Members

-   Manar
-   Jana
-   Salma
-   Fajer



# Data Availability: The datasets used in this project are not included in this repository due to confidentiality and NDA requirements.
