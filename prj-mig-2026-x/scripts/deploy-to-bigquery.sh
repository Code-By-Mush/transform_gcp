#!/usr/bin/env bash
# Deploy BigQuery DDL from artifacts/<wave>/bigquery-ddl/ using the bq CLI.
#
# Prerequisites: gcloud + bq, authenticated. Billing enabled for DML if you add seed data later.
#
# Usage:
#   ./scripts/deploy-to-bigquery.sh --wave wave-1 [--dry-run] [--with-external] [--with-lineage-views]
#   ./scripts/deploy-to-bigquery.sh --wave wave-2 [--dry-run] [--with-wave2-external]
#
# Environment: BQ_LOCATION, GCS_RAW_LANDING_URI (default gs://${GCP_PROJECT}-raw-landing)

set -euo pipefail

GCP_PROJECT="leapdataos"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSFORM_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WAVE="wave-1"
DRY_RUN=0
WITH_EXTERNAL=0
WITH_LINEAGE=0
WAVE2_EXTERNAL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wave)
      WAVE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --with-external)
      WITH_EXTERNAL=1
      shift
      ;;
    --with-lineage-views)
      WITH_LINEAGE=1
      shift
      ;;
    --with-wave2-external)
      WAVE2_EXTERNAL=1
      shift
      ;;
    -h | --help)
      head -n 30 "$0" | tail -n +2
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$WAVE" || "$WAVE" != wave-1 && "$WAVE" != wave-2 ]]; then
  echo "Use: --wave wave-1  or  --wave wave-2" >&2
  exit 1
fi

ARTIFACTS_DIR="${TRANSFORM_ROOT}/artifacts/${WAVE}"
DDL_DIR="${ARTIFACTS_DIR}/bigquery-ddl"
if [[ ! -d "$DDL_DIR" ]]; then
  echo "Missing: ${DDL_DIR}" >&2
  exit 1
fi

BQ_LOCATION="${BQ_LOCATION:-US}"
DEFAULT_GCS="gs://${GCP_PROJECT}-raw-landing"
GCS_RAW_LANDING_URI="${GCS_RAW_LANDING_URI:-$DEFAULT_GCS}"

substitute_sql() {
  sed -e "s/my-gcp-project/${GCP_PROJECT}/g" \
      -e "s|gs://my-gcp-project-raw-landing|${GCS_RAW_LANDING_URI}|g"
}

run_sql_file() {
  local path="$1"
  echo "==> $(basename "${path}")"
  local tmp
  tmp="$(mktemp)"
  substitute_sql < "${path}" > "${tmp}"
  local -a bq_args=(query --use_legacy_sql=false --project_id="${GCP_PROJECT}")
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    bq_args+=(--dry_run)
  fi
  bq "${bq_args[@]}" < "${tmp}"
  rm -f "${tmp}"
}

ensure_dataset() {
  local dataset_id="$1"
  if bq show --project_id="${GCP_PROJECT}" "${dataset_id}" &>/dev/null; then
    return 0
  fi
  echo "Creating dataset ${GCP_PROJECT}:${dataset_id} (location=${BQ_LOCATION})"
  bq mk --project_id="${GCP_PROJECT}" --dataset \
    --location="${BQ_LOCATION}" \
    --description="PRJ-MIG-2026-X ${WAVE} migration" \
    "${GCP_PROJECT}:${dataset_id}"
}

echo "Project: ${GCP_PROJECT}  |  wave: ${WAVE}  |  DDL: ${DDL_DIR}"
echo "BQ location: ${BQ_LOCATION}  |  GCS landing: ${GCS_RAW_LANDING_URI}"
[[ "${DRY_RUN}" -eq 1 ]] && echo "Mode: dry-run (CREATE uses --dry_run; missing datasets are created for real if needed)"

ensure_dataset "recall_dw"
ensure_dataset "recall_dw_landing"
ensure_dataset "recall_dw_staging"

if [[ "$WAVE" == "wave-1" ]]; then
  ORDERED_SQL=(
    "etl_batch_log.sql"
    "dim_date.sql"
    "dw_etl_rejects.sql"
    "dim_vehicle_master.sql"
    "dim_vehicle_ownership.sql"
    "dim_dealer.sql"
    "stg_dealer_master.sql"
  )
  for f in "${ORDERED_SQL[@]}"; do
    run_sql_file "${DDL_DIR}/${f}"
  done
  if [[ "${WITH_EXTERNAL}" -eq 1 ]]; then
    run_sql_file "${DDL_DIR}/ext_dealer_master.sql"
  else
    echo "==> ext_dealer_master.sql (skipped; use --with-external)"
  fi
  if [[ "${WITH_LINEAGE}" -eq 1 ]]; then
    run_sql_file "${DDL_DIR}/vw_recall_execution_lineage.sql"
  else
    echo "==> vw_recall_execution_lineage.sql (skipped; use --with-lineage-views)"
  fi
else
  # Prerequisite: run wave-1 deploy first (dims, staging, ETL log).
  ORDERED_SQL_W2=(
    "err_dealer_rejects.sql"
    "fact_campaign_vehicle.sql"
    "fact_recall_repair_orders.sql"
  )
  for f in "${ORDERED_SQL_W2[@]}"; do
    run_sql_file "${DDL_DIR}/${f}"
  done
  if [[ "${WAVE2_EXTERNAL}" -eq 1 ]]; then
    run_sql_file "${DDL_DIR}/campaign_vehicle_ext.sql"
    run_sql_file "${DDL_DIR}/recall_repair_orders_ext.sql"
  else
    echo "==> campaign_vehicle_ext / recall_repair_orders_ext (skipped; use --with-wave2-external)"
  fi
fi

echo "Done."
