#!/usr/bin/env bash
#
# deploy.sh — build the Blume site and rsync dist/ to the web server.
# See README.md in this directory.

# shellcheck disable=SC2034  # the RUN_* / INSTANCE_* variables are read by runlib
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=runlib/runlib.sh
source "$SCRIPT_DIR/runlib/runlib.sh"

DEPLOY_HOST="milos"
DEPLOY_PATH="/opt/www/kiglossar"
DEPLOY_URL="https://kiglossar.schreibauf.de"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_KEEP_DAYS=30
DRY_RUN=0
DO_BUILD=1

usage() {
  cat <<USAGE
Usage: deploy.sh [--dry-run] [--no-build] [--help]

  --dry-run   build, but only show what rsync would change
  --no-build  deploy the existing dist/ without building
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=1 ;;
    --no-build) DO_BUILD=0 ;;
    -h|--help)  usage; exit 0 ;;
    *)          echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

RUN_WHAT="website deploy"
RUN_LOG_NAME="deploy run"
RUN_UNIT="Sites"
RUN_OK_VERB="deployed"
RUN_ABORT_HINT="The site on the server may be only partly updated."
RUN_USES_MARKER=0
RUN_BYTES_FN=bytes_none
INSTANCE_NAMES=("website")
INSTANCE_CONFS=("")
INSTANCE_TITLES=("website")
INSTANCE_OUTDIRS=("")

bytes_none() { printf '0'; }

# Domain-level log: stderr only, the worker subshell tees it into the log file.
log() { printf '%s %-7s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "[INFO]" "$*" >&2; }

deploy_site() {
  local rc
  local -a rsync_cmd

  cd "$PROJECT_DIR" || return 1

  if [[ "$DO_BUILD" -eq 1 ]]; then
    if [[ ! -d node_modules ]]; then
      log "node_modules missing — installing dependencies"
      cmd_run npm ci || return 1
    fi
    log "Building the site"
    cmd_run npm run build || return 1
  else
    log "Skipping the build (--no-build)"
  fi

  if [[ ! -f dist/index.html ]]; then
    log "dist/index.html is missing — refusing to sync an empty or broken build"
    return 1
  fi

  # No -p/-o/-g: we are not root on the server, so new files get its umask.
  # (macOS openrsync has no --chmod.) --delete keeps the target an exact
  # mirror, hence the check above.
  rsync_cmd=(rsync -rlt --delete --stats --human-readable --itemize-changes
    -e "ssh -o BatchMode=yes")
  [[ "$DRY_RUN" -eq 1 ]] && rsync_cmd+=(--dry-run)
  rsync_cmd+=(dist/ "${DEPLOY_HOST}:${DEPLOY_PATH}")

  log "Syncing dist/ to ${DEPLOY_HOST}:${DEPLOY_PATH}$([[ "$DRY_RUN" -eq 1 ]] && echo ' (dry run)')"
  cmd_run "${rsync_cmd[@]}"
  rc=$?
  [[ "$rc" -eq 0 ]] && log "Done: $DEPLOY_URL"
  return "$rc"
}

run_init "$LOG_DIR" "deploy" \
  || { echo "FATAL: cannot create the log file in $LOG_DIR" >&2; exit 1; }
log_rotate "$LOG_DIR" "deploy" "$LOG_KEEP_DAYS"
if [[ -f "$SCRIPT_DIR/global.conf" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/global.conf" || fatal "global.conf could not be read"
fi
notify_init
run_traps

command -v rsync >/dev/null 2>&1 || fatal "rsync not found"
if [[ "$DO_BUILD" -eq 1 ]]; then
  command -v npm >/dev/null 2>&1 || fatal "npm not found (Node.js 22.19+ required)"
fi
notify_check_binaries

[[ "$DRY_RUN" -eq 1 ]] && log_info "Dry run: nothing will be changed on the server"
acquire_lock "$LOG_DIR/.lock" || run_end 1
run_worker_loop deploy_site
run_finish
