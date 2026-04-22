-- BigQuery DDL: FACT_RECALL_REPAIR_ORDERS
-- Mutable repair fact — 4-hourly incremental load from Service Scheduling OLTP.
-- Wave 2 — Recall Repair Order Completion Pipeline
CREATE OR REPLACE TABLE `my-gcp-project.recall_dw.FACT_RECALL_REPAIR_ORDERS`
(
  REPAIR_ORDER_KEY      INT64      NOT NULL,
  CAMPAIGN_KEY          INT64      NOT NULL,
  DEALER_KEY            INT64      NOT NULL,
  VEHICLE_GOLDEN_KEY    INT64      NOT NULL,
  REPAIR_START_DATE     DATE       NOT NULL,   -- partition column
  REPAIR_END_DATE       DATE,
  REPAIR_STATUS         STRING(50) DEFAULT 'OPEN',
  QC_PASS_FLAG          BOOL       DEFAULT FALSE,
  TECHNICIAN_ID         STRING(50),
  PARTS_COST            NUMERIC,
  LABOUR_HOURS          FLOAT64,
  BUSINESS_DAYS_TAKEN   INT64,
  _SOURCE_SYSTEM        STRING(50) DEFAULT 'SERVICE_SCHED_OLTP',
  _LOADED_AT            TIMESTAMP  DEFAULT CURRENT_TIMESTAMP(),
  _LAST_MODIFIED_AT     TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY REPAIR_START_DATE
CLUSTER BY CAMPAIGN_KEY, DEALER_KEY
OPTIONS (
  description = 'Recall repair orders — 4-hourly incremental via Cloud Data Fusion CDC'
);

-- BigQuery scalar function: IS_BUSINESS_DAY (replaces DIM_DATE.IS_BUSINESS_DAY join)
CREATE OR REPLACE FUNCTION `my-gcp-project.recall_dw.IS_BUSINESS_DAY`(d DATE)
RETURNS BOOL AS (
  EXTRACT(DAYOFWEEK FROM d) NOT IN (1, 7)
);
