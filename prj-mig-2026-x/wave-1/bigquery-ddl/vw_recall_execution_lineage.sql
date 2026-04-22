-- BigQuery: VW_RECALL_EXECUTION_LINEAGE
-- Analytical slice: active campaigns × vehicles × gold dimension × repair dealer × org hierarchy.
-- Replaces wide Oracle view (CONNECT BY + multi-join) with BQ view + mat view refresh.
-- Wave 1 — Dealer Hierarchy Network
-- Requires: FACT_CAMPAIGN_VEHICLE, DIM_RECALL_CAMPAIGN, DIM_VEHICLE_GOLDEN, FACT_RECALL_REPAIR_ORDERS, DIM_DEALER, DEALER_ANCESTOR (later-wave objects may be absent in POC).

CREATE OR REPLACE VIEW `my-gcp-project.recall_dw.VW_RECALL_EXECUTION_LINEAGE_BASE`
OPTIONS (description = 'Lineage for recall execution: enrolment, golden vehicle, repair dealer, and nearest-root via DEALER_ANCESTOR (DEPTH=1). Filter: active campaigns. Authorised-view boundary for row-level access if RLS is applied. Downstream: materialised for query cost and freshness.')
AS
SELECT
  cv.CAMPAIGN_KEY,
  rc.CAMPAIGN_CODE,
  rc.CAMPAIGN_DESCRIPTION,
  rc.RECALL_TYPE,
  cv.VEHICLE_GOLDEN_KEY,
  vg.VEHICLE_ID,
  vg.MAKE,
  vg.MODEL,
  vg.MODEL_YEAR,
  cv.STATUS                     AS ENROLMENT_STATUS,
  cv.ENROLMENT_DATE,
  cv.APPOINTMENT_KEY,
  cv.DAYS_TO_REPAIR,
  -- Dealer join via FACT_RECALL_REPAIR_ORDERS (completed repairs have a dealer)
  rr.DEALER_KEY,
  d.DEALER_ID,
  d.DEALER_NAME,
  d.REGION_CODE,
  d.COUNTRY_CODE,
  -- Hierarchy depth from pre-computed ancestor table (replaces Oracle CONNECT BY)
  anc.DEPTH                     AS DEALER_HIERARCHY_DEPTH,
  anc.ANCESTOR_ID               AS ROOT_DEALER_ID
FROM
  `my-gcp-project.recall_dw.FACT_CAMPAIGN_VEHICLE`      cv
  JOIN `my-gcp-project.recall_dw.DIM_RECALL_CAMPAIGN`   rc  ON cv.CAMPAIGN_KEY       = rc.CAMPAIGN_KEY
  JOIN `my-gcp-project.recall_dw.DIM_VEHICLE_GOLDEN`    vg  ON cv.VEHICLE_GOLDEN_KEY = vg.VEHICLE_GOLDEN_KEY
  LEFT JOIN `my-gcp-project.recall_dw.FACT_RECALL_REPAIR_ORDERS` rr
    ON cv.CAMPAIGN_KEY = rr.CAMPAIGN_KEY AND cv.VEHICLE_GOLDEN_KEY = rr.VEHICLE_GOLDEN_KEY
  LEFT JOIN `my-gcp-project.recall_dw.DIM_DEALER`       d   ON rr.DEALER_KEY = d.DEALER_KEY
  LEFT JOIN `my-gcp-project.recall_dw.DEALER_ANCESTOR`  anc
    ON d.DEALER_ID = anc.DEALER_ID AND anc.DEPTH = 1
WHERE
  rc.CAMPAIGN_STATUS = 'ACTIVE';

CREATE OR REPLACE MATERIALIZED VIEW `my-gcp-project.recall_dw.VW_RECALL_EXECUTION_LINEAGE`
  OPTIONS (
    enable_refresh = TRUE,
    refresh_interval_minutes = 60,
    description = 'Pre-aggregated/memoised result of VW_RECALL_EXECUTION_LINEAGE_BASE. Hourly refresh: balances staleness and slot cost. Use for heavy dashboards; base view for strict consistency or RLS. Replaces Oracle view materialization pattern.'
  )
AS
SELECT * FROM `my-gcp-project.recall_dw.VW_RECALL_EXECUTION_LINEAGE_BASE`;
