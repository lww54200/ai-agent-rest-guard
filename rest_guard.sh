#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${REST_GUARD_CONFIG:-./rest-guard.conf}"
STATE_FILE="${REST_GUARD_STATE:-./rest-guard-state.json}"
NOW_EPOCH="${REST_GUARD_NOW:-$(date +%s)}"

DEFAULT_MAX_UPTIME_MINUTES=240
DEFAULT_REST_MINUTES=30
DEFAULT_AGENT_ID="agent"

load_config() {
  MAX_UPTIME_MINUTES="$DEFAULT_MAX_UPTIME_MINUTES"
  REST_MINUTES="$DEFAULT_REST_MINUTES"
  AGENT_ID="$DEFAULT_AGENT_ID"
  if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
  fi
}

json_get_number() {
  local key="$1" default="$2"
  if [[ ! -f "$STATE_FILE" ]]; then echo "$default"; return; fi
  grep -o "\"$key\"[[:space:]]*:[[:space:]]*[0-9]*" "$STATE_FILE" | head -n1 | grep -o '[0-9]*$' || echo "$default"
}

write_state() {
  local started_at="$1" rest_until="$2" status="$3" reason="$4"
  cat > "$STATE_FILE" <<JSON
{
  "agent_id": "$AGENT_ID",
  "started_at": $started_at,
  "rest_until": $rest_until,
  "last_checked_at": $NOW_EPOCH,
  "status": "$status",
  "reason": "$reason"
}
JSON
}

cmd_status() {
  load_config
  local started rest_until uptime_limit rest_limit
  started="$(json_get_number started_at "$NOW_EPOCH")"
  rest_until="$(json_get_number rest_until 0)"
  uptime_limit=$((MAX_UPTIME_MINUTES * 60))
  rest_limit=$((REST_MINUTES * 60))

  if (( NOW_EPOCH < rest_until )); then
    write_state "$started" "$rest_until" "resting" "mandatory rest period active"
    echo "REST_REQUIRED until=$rest_until remaining_seconds=$((rest_until - NOW_EPOCH))"
    return 2
  fi

  local elapsed=$((NOW_EPOCH - started))
  if (( elapsed >= uptime_limit )); then
    rest_until=$((NOW_EPOCH + rest_limit))
    write_state "$((NOW_EPOCH + rest_limit))" "$rest_until" "resting" "max uptime exceeded"
    echo "REST_REQUIRED until=$rest_until remaining_seconds=$rest_limit"
    return 2
  fi

  write_state "$started" 0 "active" "within uptime budget"
  echo "ACTIVE elapsed_seconds=$elapsed remaining_seconds=$((uptime_limit - elapsed))"
}

cmd_reset() {
  load_config
  write_state "$NOW_EPOCH" 0 "active" "manual reset"
  echo "RESET started_at=$NOW_EPOCH"
}

cmd_force_rest() {
  load_config
  local rest_until=$((NOW_EPOCH + REST_MINUTES * 60))
  write_state "$NOW_EPOCH" "$rest_until" "resting" "manual rest"
  echo "REST_REQUIRED until=$rest_until remaining_seconds=$((REST_MINUTES * 60))"
}

usage() {
  cat <<'TXT'
Usage: ./rest_guard.sh [status|reset|force-rest]

Environment:
  REST_GUARD_CONFIG   Path to config file, default ./rest-guard.conf
  REST_GUARD_STATE    Path to state JSON, default ./rest-guard-state.json
  REST_GUARD_NOW      Override current epoch seconds for tests

Exit codes:
  0 active or reset successful
  2 rest is required
TXT
}

case "${1:-status}" in
  status) cmd_status ;;
  reset) cmd_reset ;;
  force-rest) cmd_force_rest ;;
  -h|--help|help) usage ;;
  *) usage; exit 64 ;;
esac
