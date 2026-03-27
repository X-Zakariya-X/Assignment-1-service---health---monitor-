#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

SERVICES_FILE="services.txt"
LOG_FILE="/var/log/health_monitor.log"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

log_event() {
  local level="$1"
  local service="$2"
  local message="$3"

  local timestamp
  timestamp=$(date +"%Y-%m-%dT%H:%M:%S%z")

  echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"service\":\"$service\",\"message\":\"$message\"}" >> "$LOG_FILE"
}

if [[ ! -f "$SERVICES_FILE" ]]; then
  echo "ERROR: $SERVICES_FILE not found. Exiting gracefully."
  exit 0
fi

if [[ ! -s "$SERVICES_FILE" ]]; then
  echo "WARNING: $SERVICES_FILE is empty. Nothing to monitor."
  exit 0
fi

total=0
healthy=0
recovered=0
failed=0

while IFS= read -r service || [[ -n "$service" ]]; do
  [[ -z "$service" || "$service" =~ ^# ]] && continue

  ((total++))

  status=$(systemctl is-active "$service" 2>/dev/null || true)

  if [[ "$status" == "active" ]]; then
    ((healthy++))
    log_event "INFO" "$service" "Service is healthy"
    continue
  fi

  log_event "WARN" "$service" "Service is not running (status=$status). Attempting restart."

  if [[ "$DRY_RUN" == true ]]; then
    log_event "INFO" "$service" "[DRY-RUN] Would restart service"
    ((failed++))
    continue
  fi

  if systemctl restart "$service" 2>/dev/null; then
    sleep 5
    new_status=$(systemctl is-active "$service" 2>/dev/null || true)

    if [[ "$new_status" == "active" ]]; then
      ((recovered++))
      log_event "INFO" "$service" "RECOVERED after restart"
    else
      ((failed++))
      log_event "ERROR" "$service" "FAILED to recover (status=$new_status)"
    fi
  else
    ((failed++))
    log_event "ERROR" "$service" "Restart command failed"
  fi

done < "$SERVICES_FILE"


echo "----------------------------------------"
echo " Service Health Summary"
echo "----------------------------------------"
printf "%-20s %d\n" "Total Checked:" "$total"
printf "%-20s %d\n" "Healthy:" "$healthy"
printf "%-20s %d\n" "Recovered:" "$recovered"
printf "%-20s %d\n" "Failed:" "$failed"
echo "----------------------------------------"

if [[ "$failed" -gt 0 ]]; then
  exit 1
else
  exit 0
fi
