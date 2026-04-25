#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t restguard)"
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT

CONFIG="$TMP_DIR/rest.conf"
STATE="$TMP_DIR/state.json"
cat > "$CONFIG" <<'CONF'
MAX_UPTIME_MINUTES=1
REST_MINUTES=2
AGENT_ID="test-agent"
CONF

run_guard(){ REST_GUARD_CONFIG="$CONFIG" REST_GUARD_STATE="$STATE" REST_GUARD_NOW="$1" bash ./rest_guard.sh "$2"; }

out="$(run_guard 1000 reset)"
[[ "$out" == RESET* ]]

out="$(run_guard 1030 status)"
[[ "$out" == ACTIVE* ]]

set +e
out="$(run_guard 1061 status)"
code=$?
set -e
[[ $code -eq 2 ]]
[[ "$out" == REST_REQUIRED* ]]

grep -q '"status": "resting"' "$STATE"

set +e
out="$(run_guard 1100 status)"
code=$?
set -e
[[ $code -eq 2 ]]
[[ "$out" == REST_REQUIRED* ]]

out="$(run_guard 1200 status)"
[[ "$out" == ACTIVE* ]]

echo "All rest_guard tests passed"
