#!/bin/bash

# Workflow Review - Session End Hook (SessionEnd)
# Cleans up session state and reminds about workflow review.
#
# Hook receives JSON on stdin with session_id, cwd, reason, etc.
# Note: Cannot block termination, just cleanup and notify.

set -E  # ERR trap works in subshells

# Error handling - log to file, don't break Claude
ERROR_LOG="/tmp/claude-workflow-review-error.log"
exec 2>>"$ERROR_LOG"

log_error() {
  echo "[$(date '+%Y-%m-%dT%H:%M:%S')] session-end: $*" >> "$ERROR_LOG"
}

trap 'log_error "Unexpected error on line $LINENO"' ERR

# Check jq availability
if ! command -v jq &>/dev/null; then
  log_error "jq not found"
  exit 0
fi

# Parse hook input
INPUT=$(cat) || { log_error "Failed to read stdin"; exit 0; }
SESSION_ID=$(jq -r '.session_id // empty' <<<"$INPUT" 2>/dev/null)
CWD=$(jq -r '.cwd // empty' <<<"$INPUT" 2>/dev/null)

# Validate SESSION_ID - only allow safe characters
if [[ -z "$SESSION_ID" ]] || [[ ! "$SESSION_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  exit 0
fi

# Check if this was a long session that didn't get reviewed
STATE_DIR="${TMPDIR:-/tmp}/claude-workflow-review"
COUNT_FILE="$STATE_DIR/count-${SESSION_ID}"

if [[ -f "$COUNT_FILE" ]]; then
  COUNT=$(cat "$COUNT_FILE" 2>/dev/null || echo 0)

  # If long session (30+) and no pending review exists, remind
  if [[ "$COUNT" -ge 30 ]] && [[ -n "$CWD" ]]; then
    PENDING_FILE="$CWD/.claude/workflow-reviews/pending-review.md"

    if [[ ! -f "$PENDING_FILE" ]]; then
      cat << 'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Session ending without workflow review.

Next time, consider running /workflow-review before ending
long sessions to capture insights while context is fresh.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
    fi
  fi

  # Cleanup session state files
  rm -f "$COUNT_FILE" 2>/dev/null || true
  rm -f "$STATE_DIR/nudged-${SESSION_ID}" 2>/dev/null || true
  rm -f "$STATE_DIR/lock-${SESSION_ID}" 2>/dev/null || true
fi
