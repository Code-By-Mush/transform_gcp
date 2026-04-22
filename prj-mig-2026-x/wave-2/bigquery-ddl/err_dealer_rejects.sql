-- BigQuery DDL: ERR_DEALER_REJECTS (dealer validation failure quarantine)
-- Source: SQL Server DW.ERR_DEALER_REJECTS  →  Target: recall_dw.error_staging
-- Migration path: Lift & Shift — schema as-is, date partition replaces SQL Server index
-- Wave 2 — Campaign Vehicle Enrolment Pipeline

CREATE OR REPLACE TABLE `my-gcp-project.recall_dw.ERR_DEALER_REJECTS`
(
  REJECT_ID          INT64       NOT NULL,   -- ROW_NUMBER() surrogate in Dataform
  CAMPAIGN_KEY       INT64,
  VEHICLE_GOLDEN_KEY INT64,
  DEALER_ID          STRING(50),
  REJECT_CODE        STRING(50),             -- e.g. INVALID_DEALER | DEALER_NOT_ENROLLED | REGION_MISMATCH
  REJECT_DESCRIPTION STRING(500),
  RAW_ROW_DATA       BYTES,                  -- serialised source row for reprocessing
  REJECTED_AT        TIMESTAMP   NOT NULL,   -- append-only; partition column
  REPROCESSED_FLAG   BOOL        DEFAULT FALSE,
  REPROCESSED_AT     TIMESTAMP,
  _SOURCE_PIPELINE   STRING(100),
  _LOADED_AT         TIMESTAMP   DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(REJECTED_AT)
OPTIONS (
  partition_expiration_days = 180,
  description               = 'Dealer validation failure quarantine — append-only. Replaces SQL Server ERR_DEALER_REJECTS. RAW_ROW_DATA stores serialised source row for reprocessing round-trips.'
);
