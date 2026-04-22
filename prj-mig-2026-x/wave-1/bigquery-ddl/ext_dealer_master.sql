-- BigQuery External Table: EXT_DEALER_MASTER
-- Zero-copy over GCS CSV landing; no ownership—typed staging in STG_DEALER_MASTER.
-- Wave 1 — Dealer Hierarchy Network

-- GCS path pattern: gs://.../dealer-master/YYYY/MM/DD/dealer_master_YYYYMMDD.csv

CREATE OR REPLACE EXTERNAL TABLE `my-gcp-project.recall_dw_landing.EXT_DEALER_MASTER`
(
  DEALER_ID           STRING
    OPTIONS (description = 'Dealer id from file; key for join to staging and dimension'),
  DEALER_NAME         STRING
    OPTIONS (description = 'Name field as in landing file'),
  DEALER_TYPE         STRING
    OPTIONS (description = 'Type label from file'),
  REGION_CODE         STRING
    OPTIONS (description = 'Region or territory code in feed'),
  COUNTRY_CODE        STRING
    OPTIONS (description = 'Country in feed'),
  PARENT_DEALER_ID    STRING
    OPTIONS (description = 'Parent in hierarchy, if present in feed'),
  ADDRESS_LINE_1      STRING
    OPTIONS (description = 'Address line 1, raw from CSV'),
  ADDRESS_LINE_2      STRING
    OPTIONS (description = 'Address line 2, raw from CSV'),
  CITY                STRING
    OPTIONS (description = 'City, raw from CSV'),
  POSTAL_CODE         STRING
    OPTIONS (description = 'Postal code, raw from CSV'),
  PHONE               STRING
    OPTIONS (description = 'Phone, raw from CSV'),
  EMAIL               STRING
    OPTIONS (description = 'Email, raw; sensitive'),
  LOAD_DATE           STRING
    OPTIONS (description = 'As landed in file (string); cast to DATE in STG for partitioning')
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://my-gcp-project-raw-landing/dealer-master/*/*.csv'],
  skip_leading_rows = 1,
  field_delimiter = ',',
  allow_quoted_newlines = TRUE,
  description = 'External (virtual) read over GCS dealer CSVs—lift of Oracle external-file feed. No BigQuery storage cost for base data; use for EL into STG. Pseudo-column _FILE_NAME supports directory partition discovery. Harden URIs in deploy (project bucket).'
);

-- Data Fusion: SFTP / file watcher → GCS Sink → path above; optional Scheduler trigger.
