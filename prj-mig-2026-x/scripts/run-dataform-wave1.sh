#!/usr/bin/env bash
# Dataform: compile + run for Wave 1 DIM_VEHICLE_GOLDEN.
# Paths: artifacts in ../artifacts/wave-1/
#
# Usage: ./run-dataform-wave1.sh | ./run-dataform-wave1.sh --compile-only
#   Extra args: ./run-dataform-wave1.sh --  [args to: npx @dataform/cli run .]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
W1="$(cd "${SCRIPT_DIR}/../artifacts/wave-1" && pwd)"
SRC_SQLX="${W1}/dataform-sqlx/dim_vehicle_golden.sqlx"
DATAFORM_ROOT="${W1}/dataform-bigquery"
DEF_DIR="${DATAFORM_ROOT}/definitions"
TARGET_SQLX="${DEF_DIR}/dim_vehicle_golden.sqlx"

COMPILE_ONLY=0
PASS_THROUGH=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --compile-only)
      COMPILE_ONLY=1
      shift
      ;;
    --)
      shift
      PASS_THROUGH+=("$@")
      break
      ;;
    -h | --help)
      head -n 18 "$0" | tail -n +2
      exit 0
      ;;
    *)
      PASS_THROUGH+=("$1")
      shift
      ;;
  esac
done

if [[ ! -f "${SRC_SQLX}" ]]; then
  echo "Missing: ${SRC_SQLX}" >&2
  exit 1
fi
mkdir -p "${DEF_DIR}"
cp -f "${SRC_SQLX}" "${TARGET_SQLX}"
cd "${DATAFORM_ROOT}"
if [[ ! -d node_modules ]]; then
  echo "Running npm install in ${DATAFORM_ROOT}..."
  npm install
fi
npx @dataform/cli compile .
if [[ "${COMPILE_ONLY}" -eq 1 ]]; then
  echo "Compile-only: done."
  exit 0
fi
if [[ ${#PASS_THROUGH[@]} -gt 0 ]]; then
  npx @dataform/cli run . "${PASS_THROUGH[@]}"
else
  npx @dataform/cli run .
fi
echo "Done. Table: leapdataos.recall_dw.DIM_VEHICLE_GOLDEN"
