#!/bin/bash

# Workflow Review - PreCompact Hook
# Fires when context reaches ~95% before compaction.
# Reminds user to capture insights before they're summarized away.

set -E

# Error handling
ERROR_LOG="/tmp/claude-workflow-review-error.log"
exec 2>>"$ERROR_LOG"

log_error() {
  echo "[$(date '+%Y-%m-%dT%H:%M:%S')] pre-compact: $*" >> "$ERROR_LOG"
}

trap 'log_error "Unexpected error on line $LINENO"' ERR

cat << 'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Context compaction starting.

If this session has insights worth preserving, run
/workflow-review now before older details are summarized.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
