-- BigQuery DDL: ETL_BATCH_LOG (cross-programme batch audit)
-- Target dataset: recall_dw.operations
-- Operational heartbeat: analogue to SSIS / Oracle batch and scheduler package lineage.
-- Wave 1 — Shared Infrastructure

CREATE OR REPLACE TABLE `my-gcp-project.recall_dw.ETL_BATCH_LOG`
(
  BATCH_ID        INT64        NOT NULL
    OPTIONS (description = 'Unique execution id for a pipeline or package run; referenced by fact and reject tables'),
  BATCH_NAME      STRING(200)  NOT NULL
    OPTIONS (description = 'Job or package name, e.g. dataform action, Composer DAG, or ETL process id'),
  SOURCE_SYSTEM   STRING(100)
    OPTIONS (description = 'Source line being extracted, e.g. ORACLE_WH, CRM_OLTP, service scheduling'),
  START_TIME      TIMESTAMP    NOT NULL
    OPTIONS (description = 'Wall-clock start of the run for SLA and failure analysis'),
  END_TIME        TIMESTAMP
    OPTIONS (description = 'Wall-clock end; NULL if still running or never completed cleanly'),
  STATUS          STRING(20)
    OPTIONS (description = 'Lifecycle: RUNNING, SUCCESS, FAILED (align with orchestration monitors)'),
  ROWS_EXTRACTED  INT64
    OPTIONS (description = 'Rows read from source or staging for this batch'),
  ROWS_LOADED     INT64
    OPTIONS (description = 'Rows successfully written to warehouse targets in this batch'),
  ROWS_REJECTED   INT64
    OPTIONS (description = 'Rows quarantined or error-routed to DW_ETL_REJECTS in this batch'),
  ERROR_MESSAGE   STRING
    OPTIONS (description = 'Top-level error summary when status is FAILED; no PII'),
  RUN_DATE        DATE         NOT NULL
    OPTIONS (description = 'Partition key, typically the business or processing date of the run'),
  _LOADED_AT      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP()
    OPTIONS (description = 'Time this log row was written in BigQuery')
)
PARTITION BY RUN_DATE
OPTIONS (
  partition_expiration_days = 365,
  description = 'Cross-programme batch and job control log: volume, success/fail, and timing for reconciliation, operations, and audit. Filled by orchestration (e.g. Cloud Composer) and ETL. Partition: RUN_DATE.'
);
