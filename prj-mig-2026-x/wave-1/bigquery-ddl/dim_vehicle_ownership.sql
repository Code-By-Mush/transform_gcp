-- BigQuery DDL: DIM_VEHICLE_OWNERSHIP
-- Source: SQL Server DW.DIM_VEHICLE_OWNERSHIP  →  Target: recall_dw.vehicle_domain
-- CRM / registration stream (analogue to SSIS Stream A). Join VEHICLE_ID to VIN in enterprise model.
-- Wave 1 — Vehicle Golden Profile

CREATE OR REPLACE TABLE `my-gcp-project.recall_dw.DIM_VEHICLE_OWNERSHIP`
(
  OWNERSHIP_KEY               INT64      NOT NULL
    OPTIONS (description = 'Warehouse surrogate for this SCD2 ownership version (not a business natural key)'),
  VEHICLE_ID                  STRING(50) NOT NULL
    OPTIONS (description = 'Business vehicle natural key; same grain as VIN in CRM and DIM_VEHICLE_MASTER join'),
  CURRENT_OWNER_CUSTOMER_KEY  INT64
    OPTIONS (description = 'FK to DIM_CUSTOMER: registered owner for this row (analogue to CUSTOMER_KEY)'),
  OWNER_TYPE                  STRING(20)
    OPTIONS (description = 'Private, fleet, or corporate ownership (routing and analytics)'),
  TRANSFER_REASON             STRING(100)
    OPTIONS (description = 'How ownership changed, e.g. private sale, inheritance, fleet reassignment'),
  OWNERSHIP_START_DATE        DATE       NOT NULL
    OPTIONS (description = 'Date this ownership interval began; table partition key'),
  OWNERSHIP_END_DATE          DATE
    OPTIONS (description = 'End of this ownership; NULL = open-ended (typically current)'),
  IS_CURRENT_OWNER            BOOL       DEFAULT TRUE
    OPTIONS (description = 'True when this row is the active owner interval for the vehicle'),
  REGISTRATION_NUMBER         STRING(20)
    OPTIONS (description = 'Jurisdiction registration or plate as supplied by source'),
  REGISTRATION_COUNTRY        STRING(5)
    OPTIONS (description = 'ISO-style market or country for registration (source-defined)'),
  _SOURCE_SYSTEM              STRING(50) DEFAULT 'SQL_SERVER_DW'
    OPTIONS (description = 'Provenance: CRM-anchored / Stream A path (SQL Server data warehouse)'),
  _LOADED_AT                  TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
    OPTIONS (description = 'Technical ingest time for this row; audit, not registration event time')
)
PARTITION BY OWNERSHIP_START_DATE
CLUSTER BY VEHICLE_ID
OPTIONS (
  description = 'Customer-facing ownership and registration SCD2 dimension. Preserves who owned the vehicle when, for compliance and “current owner” joins to the golden layer. No build-spec columns—use DIM_VEHICLE_MASTER. Partition: OWNERSHIP_START_DATE. Cluster: VEHICLE_ID.'
);
