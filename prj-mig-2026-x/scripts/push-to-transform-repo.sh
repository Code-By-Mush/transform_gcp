#!/usr/bin/env bash
# Copy PRJ-MIG-2026-X transform DDL (bigquery-ddl) and DML/definitions (dataform-sqlx) into
# the external GitHub repo, commit, and push.
#
# Prerequisites: git, ssh access to GitHub, repo clone URL (read/write), remote branch exists.
# Default remote: git@github.com:Code-By-Mush/transform_gcp.git
#
# Usage:
#   ./push-to-transform-repo.sh                 # copy + commit + push
#   ./push-to-transform-repo.sh --dry-run        # show actions only, no write to clone
#   TRANSFORM_GIT_CLONE_DIR=/path/to/clone  ./push-to-transform-repo.sh
#
# Environment:
#   TRANSFORM_REMOTE   — git URL (default below)
#   TRANSFORM_GIT_CLONE_DIR — worktree; clone created if missing
#   PUSH_BRANCH        — default main
#   COMMIT_MSG         — override one-line message

set -euo pipefail

TRANSFORM_REMOTE="${TRANSFORM_REMOTE:-git@github.com:Code-By-Mush/transform_gcp.git}"
PUSH_BRANCH="${PUSH_BRANCH:-main}"
DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    -h|--help) head -n 22 "$0" | tail -n +2; exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSFORM_STAGE="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARTIFACTS="${TRANSFORM_STAGE}/artifacts"
SYNC_NAME="prj-mig-2026-x"
DEFAULT_CLONE="${HOME}/.cache/transform_gcp_worktree"
CLONE_DIR="${TRANSFORM_GIT_CLONE_DIR:-$DEFAULT_CLONE}"
COMMIT_MSG="${COMMIT_MSG:-chore: sync PRJ-MIG-2026-X BigQuery DDL and Dataform SQLX}"

if [[ ! -d "${ARTIFACTS}/wave-1" ]]; then
  echo "Missing ${ARTIFACTS}/wave-1" >&2
  exit 1
fi

sync_tree() {
  local dest_root="$1"
  mkdir -p "${dest_root}/${SYNC_NAME}/wave-1/bigquery-ddl" \
           "${dest_root}/${SYNC_NAME}/wave-1/dataform-sqlx" \
           "${dest_root}/${SYNC_NAME}/wave-2/bigquery-ddl" \
           "${dest_root}/${SYNC_NAME}/wave-2/dataform-sqlx" \
           "${dest_root}/${SYNC_NAME}/scripts"
  if [[ -d "${ARTIFACTS}/wave-1/bigquery-ddl" ]]; then
    rsync -a --delete "${ARTIFACTS}/wave-1/bigquery-ddl/" "${dest_root}/${SYNC_NAME}/wave-1/bigquery-ddl/"
  fi
  if [[ -d "${ARTIFACTS}/wave-1/dataform-sqlx" ]]; then
    rsync -a --delete "${ARTIFACTS}/wave-1/dataform-sqlx/" "${dest_root}/${SYNC_NAME}/wave-1/dataform-sqlx/"
  fi
  if [[ -d "${ARTIFACTS}/wave-2/bigquery-ddl" ]]; then
    rsync -a --delete "${ARTIFACTS}/wave-2/bigquery-ddl/" "${dest_root}/${SYNC_NAME}/wave-2/bigquery-ddl/"
  fi
  if [[ -d "${ARTIFACTS}/wave-2/dataform-sqlx" ]]; then
    rsync -a --delete "${ARTIFACTS}/wave-2/dataform-sqlx/" "${dest_root}/${SYNC_NAME}/wave-2/dataform-sqlx/"
  fi
  if [[ -d "${ARTIFACTS}/wave-1/dataform-bigquery" ]]; then
    mkdir -p "${dest_root}/${SYNC_NAME}/wave-1/dataform-bigquery"
    rsync -a --delete --exclude=node_modules "${ARTIFACTS}/wave-1/dataform-bigquery/" \
      "${dest_root}/${SYNC_NAME}/wave-1/dataform-bigquery/"
  fi
  rsync -a "${SCRIPT_DIR}/" "${dest_root}/${SYNC_NAME}/scripts/"
  rm -rf "${dest_root}/${SYNC_NAME}/scripts/node_modules" 2>/dev/null || true
}

if [[ "${DRY}" -eq 1 ]]; then
  echo "DRY-RUN: remote=${TRANSFORM_REMOTE}"
  echo "Would rsync to ${CLONE_DIR}/${SYNC_NAME}/(wave-1, wave-2) + scripts"
  echo "from ${ARTIFACTS}"
  exit 0
fi

mkdir -p "$(dirname "${CLONE_DIR}")"
if [[ ! -d "${CLONE_DIR}/.git" ]]; then
  echo "Cloning ${TRANSFORM_REMOTE} -> ${CLONE_DIR} ..."
  git clone "${TRANSFORM_REMOTE}" "${CLONE_DIR}"
fi
git -C "${CLONE_DIR}" fetch origin 2>/dev/null || true
if git -C "${CLONE_DIR}" show-ref --verify --quiet "refs/remotes/origin/${PUSH_BRANCH}"; then
  git -C "${CLONE_DIR}" checkout -B "${PUSH_BRANCH}" "origin/${PUSH_BRANCH}"
else
  git -C "${CLONE_DIR}" checkout -B "${PUSH_BRANCH}" 2>/dev/null || true
fi
git -C "${CLONE_DIR}" pull --rebase origin "${PUSH_BRANCH}" 2>/dev/null || true

sync_tree "${CLONE_DIR}"
git -C "${CLONE_DIR}" add -A "${SYNC_NAME}/"
if git -C "${CLONE_DIR}" diff --cached --quiet; then
  echo "No changes to commit under ${SYNC_NAME}/"
  exit 0
fi
git -C "${CLONE_DIR}" -c user.email=transform-sync@local -c user.name="transform sync" \
  commit -m "${COMMIT_MSG}"
echo "Pushing to origin ${PUSH_BRANCH}..."
git -C "${CLONE_DIR}" push origin "${PUSH_BRANCH}"
echo "Done. Repo: ${TRANSFORM_REMOTE} branch ${PUSH_BRANCH}"
