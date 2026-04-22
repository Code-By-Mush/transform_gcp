#!/usr/bin/env bash
# DML seed: sample rows in DIM_VEHICLE_MASTER and DIM_VEHICLE_OWNERSHIP.
# Needs billing on project for DML. Then run: ./run-dataform-wave1.sh
#
# Usage: ./seed-wave1-sample-data.sh  |  --replace
set -euo pipefail
GCP_PROJECT="leapdataos"
REPLACE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --replace) REPLACE=1; shift ;;
    -h|--help) head -n 6 "$0" | tail -n +2; exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done
sql_delete=""
if [[ "${REPLACE}" -eq 1 ]]; then
  sql_delete=$(cat <<'EOS'
DELETE FROM `leapdataos.recall_dw.DIM_VEHICLE_OWNERSHIP` WHERE VEHICLE_ID = 'DEMO-VIN-0001';
DELETE FROM `leapdataos.recall_dw.DIM_VEHICLE_MASTER` WHERE VEHICLE_ID = 'DEMO-VIN-0001';
EOS
)
fi
sql_body=$(cat <<'EOS'
INSERT INTO `leapdataos.recall_dw.DIM_VEHICLE_MASTER` (
  VEHICLE_KEY, VEHICLE_ID, MAKE, MODEL, MODEL_YEAR, ENGINE_TYPE, BUILD_DATE,
  RECALL_ELIGIBLE_FLAG, EFFECTIVE_FROM, EFFECTIVE_TO, IS_CURRENT, _SOURCE_SYSTEM
) VALUES (
  91001, 'DEMO-VIN-0001', 'DemoMake', 'DemoModel', 2022, 'ICE', DATE '2022-03-15',
  TRUE, DATE '2022-03-15', NULL, TRUE, 'SEED_SCRIPT'
);
INSERT INTO `leapdataos.recall_dw.DIM_VEHICLE_OWNERSHIP` (
  OWNERSHIP_KEY, VEHICLE_ID, CURRENT_OWNER_CUSTOMER_KEY, OWNER_TYPE, TRANSFER_REASON,
  OWNERSHIP_START_DATE, OWNERSHIP_END_DATE, IS_CURRENT_OWNER,
  REGISTRATION_NUMBER, REGISTRATION_COUNTRY, _SOURCE_SYSTEM
) VALUES (
  92001, 'DEMO-VIN-0001', 99001, 'PRIVATE', NULL,
  DATE '2023-01-01', NULL, TRUE, NULL, NULL, 'SEED_SCRIPT'
);
EOS
)
tmp="$(mktemp)"
{ echo "${sql_delete}"; echo "${sql_body}"; } >"${tmp}"
bq query --use_legacy_sql=false --project_id="${GCP_PROJECT}" <"${tmp}"
rm -f "${tmp}"
echo "OK. Then: ./scripts/run-dataform-wave1.sh (from the transform/ directory)"
