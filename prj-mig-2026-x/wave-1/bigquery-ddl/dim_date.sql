-- BigQuery DDL: DIM_DATE (static calendar dimension)
-- Conformed time dimension for all recall facts: fiscal, business day, and keys.
-- Wave 1 — Shared Infrastructure

CREATE OR REPLACE TABLE `my-gcp-project.recall_dw.DIM_DATE`
(
  DATE_KEY        INT64       NOT NULL
    OPTIONS (description = 'Integer surrogate YYYYMMDD; join key for fact date foreign keys'),
  FULL_DATE       DATE        NOT NULL
    OPTIONS (description = 'Calendar date this row represents'),
  DAY_OF_WEEK     STRING(10)
    OPTIONS (description = 'e.g. Monday; weekend vs weekday analytics'),
  IS_BUSINESS_DAY BOOL        DEFAULT FALSE
    OPTIONS (description = 'Weekday excluding configured holidays; regulatory and SLA business-day KPIs'),
  FISCAL_YEAR     INT64
    OPTIONS (description = 'Fiscal year per org calendar, not only calendar year'),
  FISCAL_QUARTER  INT64
    OPTIONS (description = 'Fiscal quarter 1-4 for reporting and targets'),
  FISCAL_MONTH    INT64
    OPTIONS (description = 'Fiscal month in org calendar'),
  MONTH_NAME      STRING(10)
    OPTIONS (description = 'Display month name for self-service and exports'),
  YEAR_MONTH      STRING(7)
    OPTIONS (description = 'e.g. 2026-04; period bucketing in dashboards'),
  _LOADED_AT      TIMESTAMP   DEFAULT CURRENT_TIMESTAMP()
    OPTIONS (description = 'When this static row was last (re)loaded, if ETL repopulates')
)
OPTIONS (
  description = 'Preloaded calendar dimension: conformed time for all recall and campaign fact tables. Avoids ad hoc date functions on every query; encodes business vs calendar day and fiscal periods. No incremental load after initial or rolling window refresh.'
);
