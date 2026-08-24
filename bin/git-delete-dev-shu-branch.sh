#!/usr/bin/env bash
set -euo pipefail

# --- Output helpers (English messages) ---
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }
info()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m    $*"; }

# --- Parameter validation ---
# Requirement:
# - Exactly one parameter (branch name)
# - Branch name must match dev/shu/*
# - Otherwise: print error and abort

if [[ $# -ne 1 ]]; then
  error "Exactly one parameter (branch name) is required."
  echo "Usage: $(basename "$0") dev/shu/<something>"
  exit 1
fi

BRANCH="$1"

# Pattern check: must start with 'dev/shu/' and have at least one character after it
if [[ ! "$BRANCH" == dev/shu/* || "$BRANCH" == "dev/shu/" ]]; then
  error "Invalid branch name: '$BRANCH'. Expected pattern: 'dev/shu/*'"
  exit 1
fi

# Optional: ensure we are inside a Git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  error "Not a Git repository ('.git' not found)."
  exit 1
fi

# --- Delete local branch (force) ---
info "Deleting local branch: $BRANCH"
git branch -D "$BRANCH"

# --- Delete remote branch on 'origin' ---
info "Deleting remote branch on 'origin': $BRANCH"
git push origin --delete "$BRANCH"

ok "Branch '$BRANCH' deleted locally and remotely."

