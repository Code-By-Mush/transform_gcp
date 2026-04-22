-- BigQuery DDL: DIM_VEHICLE_MASTER
-- Target dataset: recall_dw.vehicle_domain
-- Wave 1 — Vehicle Golden Profile
-- Partitioned by BUILD_DATE, clustered on VEHICLE_ID
CREATE OR REPLACE TABLE `my-gcp-project.recall_dw.DIM_VEHICLE_MASTER`
(
  VEHICLE_KEY           INT64      NOT NULL
    OPTIONS (description = 'SCD2 surrogate: one per vehicle natural id + business-effective version. Primary join from facts when history not required in star paths'),
  VEHICLE_ID            STRING(50) NOT NULL
    OPTIONS (description = 'Conformed business key (typically 17-char VIN); same grain as join to ownership and campaign facts. Not PII in warehouse policy terms but still sensitive'),
  MAKE                  STRING(100)
    OPTIONS (description = 'Manufacturer brand; campaign and population breakdowns'),
  MODEL                 STRING(100)
    OPTIONS (description = 'Model line; scope often at trim/engine × model in recall rules'),
  MODEL_YEAR            INT64
    OPTIONS (description = 'Regulatory and technical scope window with BUILD_DATE and campaign attributes'),
  ENGINE_TYPE           STRING(50)
    OPTIONS (description = 'Emissions/safety/variant scope; aligns to Oracle build master'),
  TRANSMISSION_TYPE     STRING(50)
    OPTIONS (description = 'Drivetrain variant where trim-level recalls differ'),
  BUILD_DATE            DATE
    OPTIONS (description = 'Factory build date: partition key and build-window scoping. Not sale date'),
  RECALL_ELIGIBLE_FLAG  BOOL       DEFAULT FALSE
    OPTIONS (description = 'Rules-driven eligibility from warehouse/risk pipeline; not the same as in-campaign only'),
  EFFECTIVE_FROM        DATE       NOT NULL
    OPTIONS (description = 'Type-2 start of this row’s business validity for the master record'),
  EFFECTIVE_TO          DATE
    OPTIONS (description = 'Type-2 end; NULL means current open interval for that natural id'),
  IS_CURRENT            BOOL       DEFAULT TRUE
    OPTIONS (description = 'Shortcut filter for the active row per natural vehicle id; must align with EFFECTIVE_TO'),
  _SOURCE_SYSTEM        STRING(50) DEFAULT 'ORACLE_WH'
    OPTIONS (description = 'Provenance: Oracle data warehouse (Stream B analogue)'),
  _LOADED_AT            TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
    OPTIONS (description = 'Technical warehouse insert time; audit only')
)
PARTITION BY BUILD_DATE
CLUSTER BY VEHICLE_ID
OPTIONS (
  description = 'Technical and recall-eligibility vehicle dimension (analogue to Stream B / Oracle data warehouse). SCD Type 2: one row per natural vehicle id (e.g. VIN) and effective business version. Excludes ownership—use DIM_VEHICLE_OWNERSHIP. Drives scoping, golden merge, and campaign analytics. Partition: BUILD_DATE. Cluster: VEHICLE_ID.'
);
