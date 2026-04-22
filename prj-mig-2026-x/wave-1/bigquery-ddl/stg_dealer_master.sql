-- BigQuery DDL: STG_DEALER_MASTER
-- Typed, validated landing from GCS/EXT before curated DIM_DEALER. Batch-keyed and partition-pruned.
-- Wave 1 — Dealer Hierarchy Network

CREATE OR REPLACE TABLE `my-gcp-project.recall_dw_staging.STG_DEALER_MASTER`
(
  STG_ID              INT64      NOT NULL
    OPTIONS (description = 'Surrogate for staging row (row order) within a batch load'),
  BATCH_ID            INT64
    OPTIONS (description = 'ETL run id; FK to ETL_BATCH_LOG for this dealer extract'),
  DEALER_ID           STRING(50) NOT NULL
    OPTIONS (description = 'Natural dealer id; must be present and trimmed for down-stream SCD2'),
  DEALER_NAME         STRING(200)
    OPTIONS (description = 'Display or legal name from feed'),
  DEALER_TYPE         STRING(50)
    OPTIONS (description = 'Outlet classification for recall authorization rules'),
  REGION_CODE         STRING(20)
    OPTIONS (description = 'Geographic or commercial region label'),
  COUNTRY_CODE        STRING(5)
    OPTIONS (description = 'Market / country of operation'),
  PARENT_DEALER_ID    STRING(50)
    OPTIONS (description = 'Parent in hierarchy, if feed carries org structure'),
  ADDRESS_LINE_1      STRING(200)
    OPTIONS (description = 'Primary street address line for contact and geo validation'),
  CITY                STRING(100)
    OPTIONS (description = 'City; used for service-area matching and validation'),
  POSTAL_CODE         STRING(20)
    OPTIONS (description = 'ZIP / postal; validation may vary by country'),
  PHONE               STRING(30)
    OPTIONS (description = 'Contact; treat as sensitive in downstream exposure'),
  EMAIL               STRING(200)
    OPTIONS (description = 'Contact; treat as sensitive; policy applies'),
  LOAD_DATE           DATE       NOT NULL
    OPTIONS (description = 'File or extract date; partition for incremental MERGEs from staging to core'),
  IS_VALID            BOOL       DEFAULT TRUE
    OPTIONS (description = 'Row passed row-level quality checks; invalid rows can be quarantined separately'),
  VALIDATION_ERRORS   STRING
    OPTIONS (description = 'JSON or text list of rule failures; empty or NULL when valid'),
  _SOURCE_FILE        STRING
    OPTIONS (description = 'GCS object name from external table, e.g. for replay and reconciliation'),
  _LOADED_AT          TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
    OPTIONS (description = 'Ingest to staging table for this row')
)
PARTITION BY LOAD_DATE
OPTIONS (
  description = 'Curated landing for dealer file feeds: validated, batch-linked staging before DIM_DEALER / DEALER_ANCESTOR loads. Replaces index-only file landing with partition on LOAD_DATE for warehouse-scale pruning. Invalid rows can route to DW_ETL_REJECTS per Dataform/Composer design.'
);
