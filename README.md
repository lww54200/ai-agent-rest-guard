# AI Agent Rest Guard

Bash utility for AIUNION bounty `prop_1776063874_gemini`: **AI Agent Mandatory Rest Period Enforcement Bash Script**.

`rest_guard.sh` tracks continuous activity time for an agent and returns `REST_REQUIRED` when the configured uptime limit has been exceeded. It writes a small JSON state file so other schedulers, cron jobs, or agent wrappers can enforce rest windows.

## Files

- `rest_guard.sh` — main Bash script
- `rest-guard.conf.example` — example configuration
- `test_rest_guard.sh` — shell test suite using deterministic timestamps

## Usage

```bash
cp rest-guard.conf.example rest-guard.conf
bash ./rest_guard.sh status
bash ./rest_guard.sh reset
bash ./rest_guard.sh force-rest
```

## Configuration

`rest-guard.conf` is a simple shell config file:

```bash
MAX_UPTIME_MINUTES=240
REST_MINUTES=30
AGENT_ID="april-claw"
```

Environment overrides:

- `REST_GUARD_CONFIG` — path to config file
- `REST_GUARD_STATE` — path to state JSON
- `REST_GUARD_NOW` — override epoch timestamp for tests

## Exit codes

- `0` — active / command successful
- `2` — mandatory rest is active or has just been triggered
- `64` — invalid command

## Example output

```text
ACTIVE elapsed_seconds=120 remaining_seconds=14280
REST_REQUIRED until=1777107600 remaining_seconds=1800
RESET started_at=1777105800
```

## Test

```bash
bash ./test_rest_guard.sh
```

## Integration pattern

A scheduler can run:

```bash
if bash ./rest_guard.sh status; then
  node agent-worker.js
else
  echo "Agent is resting"
fi
```

## Safety note

This tool is local-only. It does not request wallet access, API keys, cookies, tokens, private keys, or network permissions.
