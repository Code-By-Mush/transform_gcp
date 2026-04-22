-- BigQuery External Table: CAMPAIGN_VEHICLE (Oracle WH export → GCS landing)
-- Source: Oracle WH.CAMPAIGN_VEHICLE  →  Target: recall_dw_landing.CAMPAIGN_VEHICLE_EXT
-- Migration path: Lift & Shift — Oracle WH export re-provisioned as GCS-backed External Table
-- Wave 2 — Campaign Vehicle Enrolment Pipeline

-- Cloud Storage landing zone:
-- gs://my-gcp-project-raw-landing/oracle-wh-exports/campaign-vehicle/YYYY/MM/DD/

CREATE OR REPLACE EXTERNAL TABLE `my-gcp-project.recall_dw_landing.CAMPAIGN_VEHICLE_EXT`
(
  VEHICLE_ID           STRING,
  CAMPAIGN_ID          STRING,
  ENROLMENT_STATUS     STRING,    -- ELIGIBLE | ENROLLED | EXCLUDED
  ENROLMENT_DATE       STRING,    -- cast to DATE in Dataform
  EXCLUSION_REASON     STRING,
  SOURCE_SYSTEM        STRING,
  EXTRACT_DATE         STRING     -- cast to DATE; used for watermark filtering
)
OPTIONS (
  format              = 'CSV',
  uris                = ['gs://my-gcp-project-raw-landing/oracle-wh-exports/campaign-vehicle/*/*.csv'],
  skip_leading_rows   = 1,
  field_delimiter     = ',',
  allow_quoted_newlines = TRUE,
  description         = 'External table over Oracle WH export landing — zero-copy access. Replaces direct Oracle WH table read in SSIS Stream B.'
);

-- Cloud Data Fusion pipeline: oracle-wh-campaign-vehicle-extract
-- Source  : Oracle WH JDBC connector (SQL: SELECT * FROM CAMPAIGN_VEHICLE WHERE EXTRACT_DATE > :watermark)
-- Target  : GCS Sink → gs://my-gcp-project-raw-landing/oracle-wh-exports/campaign-vehicle/{YYYY}/{MM}/{DD}/
-- Schedule: Cloud Scheduler → Cloud Data Fusion REST API → Daily 01:00 UTC
