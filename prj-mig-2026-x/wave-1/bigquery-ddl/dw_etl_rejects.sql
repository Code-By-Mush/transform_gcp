-- BigQuery DDL: DW_ETL_REJECTS (rejected row diagnostics — append-only quarantine)
-- Shared reject store for legacy and cloud; golden merge orphans and validation failures.
-- Wave 1 — Shared Infrastructure

CREATE OR REPLACE TABLE `my-gcp-project.recall_dw.DW_ETL_REJECTS`
(
  REJECT_ID         INT64        NOT NULL
    OPTIONS (description = 'Monotonic surrogate for the reject event; not reused'),
  BATCH_ID          INT64
    OPTIONS (description = 'ETL batch id; FK to ETL_BATCH_LOG.BATCH_ID for correlation'),
  SOURCE_SYSTEM     STRING(100)  NOT NULL
    OPTIONS (description = 'Producing system or service that emitted the bad row, e.g. DATAFORM, COMPOSER'),
  SOURCE_TABLE      STRING(200)  NOT NULL
    OPTIONS (description = 'Logical or physical source object name for triage and replay'),
  REJECT_REASON     STRING(500)
    OPTIONS (description = 'Code or free-text reason, e.g. ORPHAN ownership, validation, duplicate VIN in batch'),
  RAW_ROW_DATA      BYTES
    OPTIONS (description = 'Opaque payload for reprocess; do not log PII in open text; treat as sensitive'),
  REJECTED_AT       TIMESTAMP    NOT NULL
    OPTIONS (description = 'Event time of quarantine; append-only—never backdated in place'),
  REPROCESSED_FLAG  BOOL         DEFAULT FALSE
    OPTIONS (description = 'Set true when row has been corrected or re-ingested in a later batch'),
  REPROCESSED_AT    TIMESTAMP
    OPTIONS (description = 'When the row was cleared for reprocess or fixed upstream'),
  _LOADED_AT        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP()
    OPTIONS (description = 'Ingest to BigQuery for this log row')
)
PARTITION BY DATE(REJECTED_AT)
OPTIONS (
  partition_expiration_days = 180,
  description = 'Append-only quarantine: SSIS- and Dataform-routed bad rows, golden-merge orphans, and validation failures. Tied to BATCH_ID for end-to-end lineage. Partition: REJECTED_AT. TTL 180d per retention policy; extend for regulatory holds if required.'
);

-- Cloud Composer task: route_rejects  (excerpt showing how rejects are written)
-- task = BigQueryInsertJobOperator(
--   task_id       = "route_rejects",
--   configuration = {
--     "query": {
--       "query": """
--         INSERT INTO `my-gcp-project.recall_dw.DW_ETL_REJECTS`
--           (REJECT_ID, BATCH_ID, SOURCE_SYSTEM, SOURCE_TABLE, REJECT_REASON, RAW_ROW_DATA, REJECTED_AT)
--         SELECT
--           ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP()) + base_offset,
--           {{ batch_id }},
--           '{{ source_system }}',
--           '{{ source_table }}',
--           err_msg,
--           TO_HEX(TO_JSON_STRING(raw))   AS RAW_ROW_DATA,
--           CURRENT_TIMESTAMP()
--         FROM UNNEST({{ reject_rows }}) AS T(raw, err_msg)
--       """,
--       "useLegacySql": false
--     }
--   }
-- )
