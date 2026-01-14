#!/usr/bin/env bash
set -euo pipefail

API_URL="https://mcp.context7.com/mcp"
CACHE_DIR="/tmp/context7"
HEADERS=(-H "Content-Type: application/json" -H "Accept: application/json, text/event-stream")

usage() {
    echo "Usage: c7.sh [--list] [--force] <library-name> \"<query>\""
    echo "  --list   List cached documentation files"
    echo "  --force  Bypass cache, fetch fresh docs"
    exit 1
}

# List cached docs
if [[ "${1:-}" == "--list" ]]; then
    mkdir -p "$CACHE_DIR"
    if ls "$CACHE_DIR"/*.md &>/dev/null; then
        ls -lh "$CACHE_DIR"/*.md
    else
        echo "No cached docs in $CACHE_DIR"
    fi
    exit 0
fi

# Parse args
FORCE=false
if [[ "${1:-}" == "--force" ]]; then
    FORCE=true
    shift
fi

if [[ $# -lt 2 ]]; then
    usage
fi

LIBRARY="$1"
QUERY="$2"
CACHE_FILE="$CACHE_DIR/$LIBRARY.md"

# Check cache
if [[ "$FORCE" == "false" && -f "$CACHE_FILE" ]]; then
    AGE=$(( ($(date +%s) - $(stat -c %Y "$CACHE_FILE")) / 3600 ))
    echo "CACHED: $CACHE_FILE (${AGE}h old)"
    exit 0
fi

# Resolve library ID
resolve_payload=$(jq -n \
    --arg query "$QUERY" \
    --arg lib "$LIBRARY" \
    '{jsonrpc:"2.0",method:"tools/call",params:{name:"resolve-library-id",arguments:{query:$query,libraryName:$lib}},id:1}')

resolve_response=$(curl -s "$API_URL" "${HEADERS[@]}" -d "$resolve_payload" 2>&1) || {
    echo "API_ERROR: Failed to connect to Context7" >&2
    exit 3
}

# Check for rate limit
if echo "$resolve_response" | grep -qi "rate.limit"; then
    echo "RATE_LIMITED: Context7 rate limit hit" >&2
    exit 2
fi

# Extract library ID and title
response_text=$(echo "$resolve_response" | jq -r '.result.content[0].text')
library_id=$(echo "$response_text" | grep -oP 'Context7-compatible library ID: \K[^\n]+' | head -1)
library_title=$(echo "$response_text" | grep -oP '^\- Title: \K.+' | head -1)

if [[ -z "$library_id" || "$library_id" == "null" ]]; then
    echo "NOT_FOUND: Library '$LIBRARY' not found in Context7" >&2
    echo "Response: $response_text" >&2
    exit 1
fi

# Validate match - check if library name appears in ID or title (case-insensitive)
library_lower=$(echo "$LIBRARY" | tr '[:upper:]' '[:lower:]')
id_lower=$(echo "$library_id" | tr '[:upper:]' '[:lower:]')
title_lower=$(echo "$library_title" | tr '[:upper:]' '[:lower:]')

if [[ "$id_lower" != *"$library_lower"* && "$title_lower" != *"$library_lower"* ]]; then
    echo "FUZZY_MATCH: Requested '$LIBRARY' but Context7 matched '$library_title' ($library_id)" >&2
    exit 4
fi

# Query docs
query_payload=$(jq -n \
    --arg libId "$library_id" \
    --arg query "$QUERY" \
    '{jsonrpc:"2.0",method:"tools/call",params:{name:"query-docs",arguments:{libraryId:$libId,query:$query}},id:1}')

query_response=$(curl -s "$API_URL" "${HEADERS[@]}" -d "$query_payload" 2>&1) || {
    echo "API_ERROR: Failed to fetch docs from Context7" >&2
    exit 3
}

# Check for rate limit
if echo "$query_response" | grep -qi "rate.limit"; then
    echo "RATE_LIMITED: Context7 rate limit hit" >&2
    exit 2
fi

# Extract docs
docs=$(echo "$query_response" | jq -r '.result.content[0].text')

if [[ -z "$docs" || "$docs" == "null" ]]; then
    echo "API_ERROR: Empty response from Context7" >&2
    exit 3
fi

# Write to cache
mkdir -p "$CACHE_DIR"
cat > "$CACHE_FILE" << EOF
# $LIBRARY Documentation

> Fetched from Context7 on $(date -Iseconds)
> Library ID: $library_id
> Query: "$QUERY"

---

$docs
EOF

echo "$CACHE_FILE"
