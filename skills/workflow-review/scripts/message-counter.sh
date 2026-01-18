#!/bin/bash

# Workflow Review - Message Counter Hook (UserPromptSubmit)
# Counts messages per session, nudges after threshold reached.
#
# Hook receives JSON on stdin with session_id, cwd, etc.

set -E  # ERR trap works in subshells

# Error handling - log to file, don't break Claude
ERROR_LOG="/tmp/claude-workflow-review-error.log"
exec 2>>"$ERROR_LOG"

log_error() {
  echo "[$(date '+%Y-%m-%dT%H:%M:%S')] message-counter: $*" >> "$ERROR_LOG"
}

trap 'log_error "Unexpected error on line $LINENO"' ERR

# Check jq availability
if ! command -v jq &>/dev/null; then
  log_error "jq not found"
  exit 0
fi

# Config
THRESHOLD=30
STATE_DIR="${TMPDIR:-/tmp}/claude-workflow-review"

# Parse session_id from hook input
INPUT=$(cat) || { log_error "Failed to read stdin"; exit 0; }
SESSION_ID=$(jq -r '.session_id // empty' <<<"$INPUT" 2>/dev/null) || {
  log_error "Failed to parse session_id from input"
  exit 0
}

# Validate SESSION_ID - only allow safe characters (alphanumeric, dash, underscore)
if [[ -z "$SESSION_ID" ]] || [[ ! "$SESSION_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  [[ -n "$SESSION_ID" ]] && log_error "Invalid session_id format: $SESSION_ID"
  exit 0
fi

# Ensure state directory exists with restricted permissions
mkdir -p "$STATE_DIR" 2>/dev/null && chmod 700 "$STATE_DIR" 2>/dev/null || {
  log_error "Failed to create state dir: $STATE_DIR"
  exit 0
}

COUNT_FILE="$STATE_DIR/count-${SESSION_ID}"
NUDGED_FILE="$STATE_DIR/nudged-${SESSION_ID}"
LOCK_FILE="$STATE_DIR/lock-${SESSION_ID}"

# Atomic increment with flock
(
  flock -w 5 200 || { log_error "Failed to acquire lock"; exit 0; }

  # Increment counter
  COUNT=$(($(cat "$COUNT_FILE" 2>/dev/null || echo 0) + 1))
  printf '%s' "$COUNT" > "$COUNT_FILE" 2>/dev/null || {
    log_error "Failed to write count file"
    exit 0
  }

  # Nudge once when threshold reached (use -ge to handle any skipped values)
  if [[ "$COUNT" -ge "$THRESHOLD" ]] && [[ ! -f "$NUDGED_FILE" ]]; then
    touch "$NUDGED_FILE" 2>/dev/null
    cat << 'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Long session detected (~30 messages).

Consider running /workflow-review to capture insights
and identify workflow improvements before context fades.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
  fi
) 200>"$LOCK_FILE"
