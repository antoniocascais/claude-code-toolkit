#!/bin/bash

# Workflow Review - Get Transcript Path
# Finds the current session's transcript JSONL file path.
#
# Usage: get-transcript-path.sh [cwd]
# Output: Full path to current session's JSONL transcript

set -E

ERROR_LOG="/tmp/claude-workflow-review-error.log"
exec 2>>"$ERROR_LOG"

log_error() {
  echo "[$(date '+%Y-%m-%dT%H:%M:%S')] get-transcript-path: $*" >> "$ERROR_LOG"
}

trap 'log_error "Unexpected error on line $LINENO"' ERR

# Check jq availability
if ! command -v jq &>/dev/null; then
  log_error "jq not found"
  exit 1
fi

# Get cwd from argument or use current directory
CWD="${1:-$(pwd)}"

# Encode path: /foo/bar → -foo-bar
ENCODED_PATH=$(echo "$CWD" | tr '/' '-')

# Build projects folder path
PROJECTS_DIR="$HOME/.claude/projects"
PROJECT_FOLDER="$PROJECTS_DIR/$ENCODED_PATH"

if [[ ! -d "$PROJECT_FOLDER" ]]; then
  log_error "Project folder not found: $PROJECT_FOLDER"
  exit 1
fi

# Find current session from sessions-index.json (most recent by modified time)
INDEX_FILE="$PROJECT_FOLDER/sessions-index.json"

if [[ ! -f "$INDEX_FILE" ]]; then
  log_error "Sessions index not found: $INDEX_FILE"
  exit 1
fi

# Get the session with highest messageCount that's not a sidechain
TRANSCRIPT_PATH=$(jq -r '
  .entries
  | map(select(.isSidechain != true))
  | sort_by(.fileMtime)
  | last
  | .fullPath
' "$INDEX_FILE" 2>/dev/null)

if [[ -z "$TRANSCRIPT_PATH" ]] || [[ "$TRANSCRIPT_PATH" == "null" ]]; then
  log_error "Could not find current session in index"
  exit 1
fi

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  log_error "Transcript file not found: $TRANSCRIPT_PATH"
  exit 1
fi

echo "$TRANSCRIPT_PATH"
