-- BigQuery External Table: RECALL_REPAIR_ORDERS (Service Scheduling OLTP → GCS via CDC)
-- Source: Service Scheduling OLTP.RECALL_REPAIR_ORDERS  →  Target: recall_dw_landing.RECALL_REPAIR_ORDERS_EXT
-- Migration path: Lift & Shift — Cloud Data Fusion CDC connector replaces watermark SQL extract
-- Wave 2 — Recall Repair Order Completion Pipeline

CREATE OR REPLACE EXTERNAL TABLE `my-gcp-project.recall_dw_landing.RECALL_REPAIR_ORDERS_EXT`
(
  REPAIR_ORDER_ID      STRING,
  CAMPAIGN_ID          STRING,
  VEHICLE_ID           STRING,
  DEALER_ID            STRING,
  TECHNICIAN_ID        STRING,
  REPAIR_STATUS        STRING,   -- OPEN | IN_PROGRESS | COMPLETED | CANCELLED
  QC_PASS_FLAG         STRING,   -- 'Y' / 'N' — cast to BOOL in staging
  REPAIR_START_DATE    STRING,
  REPAIR_END_DATE      STRING,
  PARTS_COST           STRING,
  LABOUR_HOURS         STRING,
  LAST_MODIFIED_DATE   STRING,   -- watermark column (no index on OLTP — CDC preferred)
  EXTRACT_TIMESTAMP    STRING
)
OPTIONS (
  format              = 'CSV',
  uris                = ['gs://my-gcp-project-raw-landing/service-sched-oltp/recall-repair-orders/*/*.csv'],
  skip_leading_rows   = 1,
  field_delimiter     = ',',
  allow_quoted_newlines = TRUE,
  description         = 'External table over Service Scheduling OLTP CDC export landing. Cloud Data Fusion CDC connector replaces 4-hourly watermark SQL extract (LAST_MODIFIED_DATE unindexed on OLTP).'
);

-- Cloud Data Fusion CDC pipeline: service-sched-recall-repair-cdc
-- Source  : JDBC Realtime (Service Scheduling OLTP) — change-data-capture mode
-- Filter  : table = RECALL_REPAIR_ORDERS
-- Target  : GCS Sink (micro-batch every 15 min) →
--           gs://my-gcp-project-raw-landing/service-sched-oltp/recall-repair-orders/{YYYY}/{MM}/{DD}/
-- Watermark stored in: Airflow Variable RECALL_REPAIR_ORDERS__HIGH_WATER_MARK (XCom-passed)
