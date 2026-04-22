-- BigQuery DDL: FACT_CAMPAIGN_VEHICLE
-- Central recall fact — mutable STATUS, DAYS_TO_REPAIR written by two pipelines.
-- Wave 2 — Campaign Vehicle Enrolment Pipeline
CREATE OR REPLACE TABLE `my-gcp-project.recall_dw.FACT_CAMPAIGN_VEHICLE`
(
  CAMPAIGN_VEHICLE_KEY    INT64      NOT NULL,
  CAMPAIGN_KEY            INT64      NOT NULL,
  VEHICLE_GOLDEN_KEY      INT64      NOT NULL,
  CUSTOMER_KEY            INT64,
  ENROLMENT_DATE          DATE       NOT NULL,   -- partition column
  STATUS                  STRING(50) DEFAULT 'PENDING',
  APPOINTMENT_KEY         INT64,
  DAYS_TO_REPAIR          FLOAT64,
  REPAIR_COMPLETION_DATE  DATE,
  _SOURCE_SYSTEM          STRING(50) DEFAULT 'DATAFORM',
  _LOADED_AT              TIMESTAMP  DEFAULT CURRENT_TIMESTAMP(),
  _LAST_MODIFIED_AT       TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY ENROLMENT_DATE
CLUSTER BY CAMPAIGN_KEY, VEHICLE_GOLDEN_KEY
OPTIONS (
  description = 'Central recall fact — dual-writer: enrolment pipeline + repair completion sync'
);
