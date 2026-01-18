#!/bin/bash

# Workflow Review - Session Start Hook (SessionStart)
# Checks for pending workflow review from previous session.
#
# Hook receives JSON on stdin with session_id, cwd, etc.

set -E  # ERR trap works in subshells

# Error handling - log to file, don't break Claude
ERROR_LOG="/tmp/claude-workflow-review-error.log"
exec 2>>"$ERROR_LOG"

log_error() {
  echo "[$(date '+%Y-%m-%dT%H:%M:%S')] session-start: $*" >> "$ERROR_LOG"
}

trap 'log_error "Unexpected error on line $LINENO"' ERR

# Check jq availability
if ! command -v jq &>/dev/null; then
  log_error "jq not found"
  exit 0
fi

# Parse hook input
INPUT=$(cat) || { log_error "Failed to read stdin"; exit 0; }
CWD=$(jq -r '.cwd // empty' <<<"$INPUT" 2>/dev/null) || {
  log_error "Failed to parse cwd from input"
  exit 0
}

if [[ -z "$CWD" ]]; then
  exit 0
fi

# Check for pending review in project's .claude/workflow-reviews/
PENDING_FILE="$CWD/.claude/workflow-reviews/pending-review.md"

if [[ -f "$PENDING_FILE" ]]; then
  cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Previous session left workflow insights to review.

Run /workflow-review to process recommendations from:
  $PENDING_FILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
fi

# Reset message counter for fresh session (clean old state)
STATE_DIR="${TMPDIR:-/tmp}/claude-workflow-review"
SESSION_ID=$(jq -r '.session_id // empty' <<<"$INPUT" 2>/dev/null)

# Validate SESSION_ID before cleanup
if [[ -n "$SESSION_ID" ]] && [[ "$SESSION_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  rm -f "$STATE_DIR/count-${SESSION_ID}" 2>/dev/null || true
  rm -f "$STATE_DIR/nudged-${SESSION_ID}" 2>/dev/null || true
  rm -f "$STATE_DIR/lock-${SESSION_ID}" 2>/dev/null || true
fi
