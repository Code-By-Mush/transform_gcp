/** BigQuery tables created outside Dataform (e.g. deploy-to-bigquery.sh DDL). */
const projectId = "leapdataos";

declare({ database: projectId, schema: "recall_dw", name: "DIM_VEHICLE_MASTER" });
declare({ database: projectId, schema: "recall_dw", name: "DIM_VEHICLE_OWNERSHIP" });
