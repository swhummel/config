#!/usr/bin/env bash
set -euo pipefail

LOCK_FILE="/usr/local/bt/ModuleTest/jenkins-run.log"

# Try to acquire a non-blocking flock on the file.
# On success: print "not locked" and return 0.
# On failure: print "LOCKED" and return 1.
check_lock() {
  if flock -n "$LOCK_FILE" -c 'echo ok' >/dev/null 2>&1; then
    echo "not locked"
    return 0
  else
    echo "LOCKED"
    return 1
  fi
}

# Helper: describe a PID (pid, user, command)
describe_pid() {
  local pid="$1"
  ps -o pid=,user=,comm= -p "$pid" 2>/dev/null | awk '{$1=$1};1'
}

echo "Checking lock on: $LOCK_FILE"
if check_lock; then
  exit 0
fi

echo "File appears to be LOCKED."
echo "Listing processes that currently hold the file (lsof):"
# Show full lsof table for transparency
sudo lsof -nP -- "$LOCK_FILE" || true

# Collect unique PIDs holding the file
mapfile -t PIDS < <(sudo lsof -t -- "$LOCK_FILE" | sort -u || true)

if [[ ${#PIDS[@]} -eq 0 ]]; then
  echo "No PIDs are holding the file (race condition or transient lock)."
else
  echo "Found PIDs: ${PIDS[*]}"
  echo "Detail (pid user command):"
  for pid in "${PIDS[@]}"; do
    describe_pid "$pid" || true
  done

  echo "Sending SIGTERM to holders..."
  for pid in "${PIDS[@]}"; do
    printf '  SIGTERM -> %s  ' "$pid"
    describe_pid "$pid" || true
    sudo kill -TERM "$pid" 2>/dev/null || true
  done

  # Wait briefly to allow graceful shutdown
  sleep 2

  # Check which PIDs are still alive
  REMAIN=()
  for pid in "${PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      REMAIN+=("$pid")
    fi
  done

  if [[ ${#REMAIN[@]} -gt 0 ]]; then
    echo "Still running after SIGTERM, sending SIGKILL:"
    for pid in "${REMAIN[@]}"; do
      printf '  SIGKILL -> %s  ' "$pid"
      describe_pid "$pid" || true
      sudo kill -KILL "$pid" 2>/dev/null || true
    done
  else
    echo "All processes terminated gracefully after SIGTERM."
  fi
fi

echo "Re-checking lock:"
if ! check_lock; then
  echo "File is still LOCKED. Current holders (lsof):"
  sudo lsof -nP -- "$LOCK_FILE" || true
  exit 1
fi

echo "File is not locked anymore. Verifying with lsof (should be empty or none):"
sudo lsof -nP -- "$LOCK_FILE" || true
