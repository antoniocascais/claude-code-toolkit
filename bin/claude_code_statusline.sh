#!/bin/bash

# Claude Code Status Line Script
# Displays current directory, git branch, and model in a formatted status line

# Configuration
USAGE_LOG="/tmp/usage.log"
USAGE_LOCK="/tmp/usage_refresh.lock"
USAGE_SCRIPT="$HOME/.claude/claude_code_capture_usage.py"
REFRESH_INTERVAL=300   # 5 minutes in seconds
LOCK_TIMEOUT=60        # Consider lock stale after 60 seconds
USAGE_CAPTURE_WAIT=3   # Seconds to wait for capture when refreshing usage log

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
dir=$(echo "$input" | jq -r '.cwd')
#dir=$(echo "$input" )
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed')
exceeds_tokens=$(echo "$input" | jq -r '.exceeds_200k_tokens')
workspace_current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
workspace_project_dir=$(echo "$input" | jq -r '.workspace.project_dir')
model_name=$(echo "$input" | jq -r '.model.display_name // "unknown"')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')


# Check if usage refresh is needed
needs_refresh() {
    if [[ ! -f "$USAGE_LOG" ]]; then
        return 0  # File doesn't exist, needs refresh
    fi

    local current_time=$(date +%s)
    local file_time=$(stat -c %Y "$USAGE_LOG" 2>/dev/null || echo 0)
    local age=$((current_time - file_time))

    if (( age > REFRESH_INTERVAL )); then
        return 0  # File is stale
    fi

    return 1  # File is fresh
}

# Acquire lock atomically (returns 0 on success, 1 on failure)
acquire_lock() {
    # Clean up leftover file lock from old implementation
    if [[ -f "$USAGE_LOCK" ]]; then
        rm -f "$USAGE_LOCK" 2>/dev/null
    fi

    if mkdir "$USAGE_LOCK" 2>/dev/null; then
        return 0  # Lock acquired successfully
    fi

    # Lock exists as directory, check if it's stale
    if [[ -d "$USAGE_LOCK" ]]; then
        local current_time=$(date +%s)
        local lock_time=$(stat -c %Y "$USAGE_LOCK" 2>/dev/null || echo 0)
        local lock_age=$((current_time - lock_time))

        if (( lock_age > LOCK_TIMEOUT )); then
            # Stale lock, try to remove and re-acquire
            rmdir "$USAGE_LOCK" 2>/dev/null
            if mkdir "$USAGE_LOCK" 2>/dev/null; then
                return 0  # Lock acquired after cleanup
            fi
        fi
    fi

    return 1  # Could not acquire lock
}

# Release lock
release_lock() {
    rmdir "$USAGE_LOCK" 2>/dev/null
}

# Trigger background refresh
trigger_refresh() {
    if ! needs_refresh; then
        return  # No refresh needed
    fi

    # Verify script exists and is readable
    if [[ ! -f "$USAGE_SCRIPT" ]]; then
        return  # Script missing, skip refresh
    fi

    # Try to acquire lock atomically
    if ! acquire_lock; then
        return  # Another process is already refreshing
    fi

    local run_synchronously=0
    if [[ ! -f "$USAGE_LOG" ]]; then
        run_synchronously=1
    fi

    refresh_usage() {
        python3 "$USAGE_SCRIPT" --silent --wait "$USAGE_CAPTURE_WAIT" >/dev/null 2>&1
    }

    if (( run_synchronously )); then
        refresh_usage
        release_lock
    else
        (
            refresh_usage
            release_lock
        ) &
        disown
    fi
}

# Get git branch if in a git repository
get_git_branch() {
    if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
        local branch=$(git -C "$dir" branch --show-current 2>/dev/null)
        if [[ -n "$branch" ]]; then
            echo "$branch"
        else
            # Fallback for detached HEAD state
            git -C "$dir" describe --all --exact-match HEAD 2>/dev/null | sed 's/^.*\///' || echo "detached"
        fi
    else
        echo ""
    fi
}

# Format model name with color coding (orange like git branch)
format_model() {
    local model=$1
    echo "\e[38;5;208m$model\e[0m"
}

# Format cost with color coding
format_cost() {
    local cost=$1
    local formatted=$(LC_NUMERIC=C printf "%.2f" "$cost")

    local color="\e[38;5;119m"  # Green: <$1
    if (( $(echo "$cost > 10" | bc -l) )); then
        color="\e[38;5;196m"    # Red: >$10
    elif (( $(echo "$cost > 5" | bc -l) )); then
        color="\e[38;5;208m"    # Orange: $5-10
    elif (( $(echo "$cost > 1" | bc -l) )); then
        color="\e[38;5;220m"    # Yellow: $1-5
    fi

    echo "${color}\$${formatted}\e[0m"
}

# Format duration display
format_duration() {
    local ms=$1

    if (( ms < 1000 )); then
        echo "${ms}ms"
    elif (( ms < 60000 )); then
        local seconds=$(awk "BEGIN {printf \"%.1f\", $ms / 1000}")
        echo "${seconds}s"
    else
        local minutes=$((ms / 60000))
        local remaining_ms=$((ms % 60000))
        local remaining_seconds=$(awk "BEGIN {printf \"%.0f\", $remaining_ms / 1000}")
        echo "${minutes}m ${remaining_seconds}s"
    fi
}

# Format lines added/removed display
format_lines() {
    local added=$1
    local removed=$2

    if [[ "$added" == "null" ]]; then added=0; fi
    if [[ "$removed" == "null" ]]; then removed=0; fi

    if [[ $added -eq 0 && $removed -eq 0 ]]; then
        echo ""
    else
        echo "\e[38;5;113m+${added}\e[0m/\e[38;5;196m-${removed}\e[0m lines"
    fi
}

# Format token warning display
format_token_warning() {
    local exceeds=$1

    if [[ "$exceeds" == "true" ]]; then
        echo " \e[38;5;196m⚠️200k\e[0m"
    else
        echo ""
    fi
}

# Format context window usage
#
# Claude Code reserves a 22.5% "autocompact buffer" for compaction operations.
# This means compaction triggers at ~77.5% raw usage (77.5 + 22.5 = 100%).
# We show RAW usage percentage but color-code based on proximity to compaction:
#   - Green (0-40%):  plenty of room (effective 0-62%)
#   - Yellow (41-55%): getting full (effective 63-77%)
#   - Red (56%+):     compaction imminent (effective 78%+)
format_ctx_usage() {
    local used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
    local window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

    [[ "$window_size" -eq 0 ]] && return

    local total_k=$((window_size / 1000))
    local used_k=$((window_size * used_pct / 100000))

    # Color based on proximity to compaction (buffer-aware thresholds)
    local color="\e[38;5;119m"  # Green
    if (( used_pct > 55 )); then
        color="\e[38;5;196m"    # Red
    elif (( used_pct > 40 )); then
        color="\e[38;5;220m"    # Yellow
    fi

    echo "\e[38;5;246mctx:\e[0m ${color}${used_k}k/${total_k}k (${used_pct}%)\e[0m"
}

# Detect dependency errors recorded in the usage log
get_usage_error() {
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo ""
        return
    fi

    local first_line
    first_line=$(head -n 1 "$USAGE_LOG" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ "$first_line" == ERROR:* ]]; then
        echo "${first_line#ERROR: }"
    fi
}

# Parse usage log for session percentage
parse_session_usage() {
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo ""
        return
    fi

    local percentage=""
    local session_line
    session_line=$(grep -m 1 "Current session" "$USAGE_LOG")

    if [[ -n "$session_line" ]]; then
        # Extract from same line: "9%used" or "9% used"
        percentage=$(echo "$session_line" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
    fi

    # Fallback: check next line
    if [[ -z "$percentage" ]]; then
        session_line=$(grep -A 1 "Current session" "$USAGE_LOG" | tail -1)
        percentage=$(echo "$session_line" | grep -o '[0-9]\+%' | head -1 | tr -d '%')
    fi

    echo "${percentage:-0}"
}

# Parse usage log for session reset time
parse_session_reset() {
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo ""
        return
    fi

    local session_line
    session_line=$(grep -m 1 "Current session" "$USAGE_LOG")

    if [[ -n "$session_line" ]]; then
        # Extract "Resets8pm" or "Resets 8pm" -> "8pm"
        local reset_info
        reset_info=$(echo "$session_line" | grep -oE 'Resets ?[0-9]+:?[0-9]*[ap]m' | sed 's/Resets *//')
        if [[ -n "$reset_info" ]]; then
            echo "$reset_info"
            return
        fi
    fi

    # Fallback: check for "Resets" on next lines
    local reset_line
    reset_line=$(grep -A 2 "Current session" "$USAGE_LOG" | grep "Resets" | head -1)
    if [[ -n "$reset_line" ]]; then
        echo "$reset_line" | sed 's/^[[:space:]]*Resets //' | sed 's/ (.*$//'
    fi
}

# Parse usage log for week percentage
parse_week_usage() {
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo ""
        return
    fi

    local week_line
    week_line=$(grep -A 1 "Current week (all models)" "$USAGE_LOG" | tail -1)

    local percentage=""
    if [[ -n "$week_line" ]]; then
        percentage=$(echo "$week_line" | grep -o '[0-9]\+%' | head -1 | tr -d '%')
    fi

    if [[ -z "$percentage" ]]; then
        week_line=$(grep -m 1 "Week:" "$USAGE_LOG")
        if [[ -n "$week_line" ]]; then
            percentage=$(echo "$week_line" | sed -n 's/.*Week:[^0-9]*\([0-9][0-9]*\)%.*/\1/p')
        fi
    fi

    echo "${percentage:-0}"
}

# Parse usage log for week reset time
parse_week_reset() {
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo ""
        return
    fi

    local reset_line
    reset_line=$(grep -A 2 "Current week (all models)" "$USAGE_LOG" | grep "Resets" | head -1)
    local reset_info=""

    if [[ -n "$reset_line" ]]; then
        reset_info=$(echo "$reset_line" | sed 's/^[[:space:]]*Resets //' | sed 's/ (.*$//')
    fi

    if [[ -z "$reset_info" ]]; then
        local week_line
        week_line=$(grep -m 1 "Week:" "$USAGE_LOG")

        if [[ -n "$week_line" ]]; then
            local after_arrow
            after_arrow=$(echo "$week_line" | awk -F "↻" 'NF>1 {print $2}')
            if [[ -n "$after_arrow" ]]; then
                after_arrow=${after_arrow%%│*}
                after_arrow=${after_arrow%%┘*}
                after_arrow=$(echo "$after_arrow" | sed 's/^[[:space:]]*//;s/[[:space:]─]*$//')
                reset_info="$after_arrow"
            fi
        fi
    fi

    echo "$reset_info"
}

# Calculate how long ago the usage log was updated
get_usage_age() {
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "never"
        return
    fi

    local current_time=$(date +%s)
    local file_time=$(stat -c %Y "$USAGE_LOG" 2>/dev/null || echo 0)
    local age=$((current_time - file_time))

    if (( age < 60 )); then
        echo "${age}s"
    elif (( age < 3600 )); then
        local minutes=$((age / 60))
        echo "${minutes}m"
    elif (( age < 86400 )); then
        local hours=$((age / 3600))
        echo "${hours}h"
    else
        local days=$((age / 86400))
        echo "${days}d"
    fi
}

# Add ordinal suffix to day number
add_ordinal() {
    local num=$1
    case $num in
        1|21|31) echo "${num}st" ;;
        2|22) echo "${num}nd" ;;
        3|23) echo "${num}rd" ;;
        *) echo "${num}th" ;;
    esac
}

# Format reset time with ordinal suffix
format_reset_time() {
    local reset_str=$1

    if [[ -z "$reset_str" ]]; then
        echo ""
        return
    fi

    # Parse "Oct 8, 10:59pm" format
    if [[ "$reset_str" =~ ^([A-Za-z]+)[[:space:]]+([0-9]+),[[:space:]]+(.+)$ ]]; then
        local month="${BASH_REMATCH[1]}"
        local day="${BASH_REMATCH[2]}"
        local time="${BASH_REMATCH[3]}"
        local day_with_suffix=$(add_ordinal "$day")
        echo "${day_with_suffix} ${month}. ${time}"
    else
        # Fallback: just return the original string
        echo "$reset_str"
    fi
}

# Format usage display
format_usage_display() {
    local usage_error=$(get_usage_error)

    if [[ -n "$usage_error" ]]; then
        local display=""
        display+=" \e[38;5;240m│\e[0m"
        display+=" \e[38;5;246mUsage:\e[0m \e[38;5;196m⚠ ${usage_error}\e[0m"
        echo -e "$display"
        return
    fi

    local session_pct=$(parse_session_usage)
    local session_reset=$(parse_session_reset)
    local week_pct=$(parse_week_usage)
    local week_reset=$(parse_week_reset)
    local age=$(get_usage_age)

    # Only hide if data is truly missing (empty string), not if it's 0%
    if [[ -z "$session_pct" ]] && [[ -z "$week_pct" ]]; then
        # No usage data available
        echo ""
        return
    fi

    # Default to 0 if empty
    session_pct=${session_pct:-0}
    week_pct=${week_pct:-0}

    # Color based on usage percentage
    # Green: 0-30%, Yellow: 30.01-50%, Orange: 50.01-80%, Red: > 80%
    local session_color="\e[38;5;119m"  # Green (default)
    if (( session_pct > 80 )); then
        session_color="\e[38;5;196m"  # Red
    elif (( session_pct > 50 )); then
        session_color="\e[38;5;208m"  # Orange
    elif (( session_pct > 30 )); then
        session_color="\e[38;5;220m"  # Yellow
    fi

    local week_color="\e[38;5;119m"  # Green (default)
    if (( week_pct > 80 )); then
        week_color="\e[38;5;196m"  # Red
    elif (( week_pct > 50 )); then
        week_color="\e[38;5;208m"  # Orange
    elif (( week_pct > 30 )); then
        week_color="\e[38;5;220m"  # Yellow
    fi

    # Format reset times with ordinal suffix
    local session_reset_formatted=$(format_reset_time "$session_reset")
    local week_reset_formatted=$(format_reset_time "$week_reset")

    # Build the display string
    local display=""
    display+=" \e[38;5;240m│\e[0m"
    display+=" \e[38;5;246mSession:\e[0m ${session_color}${session_pct}%\e[0m"
    if [[ -n "$session_reset_formatted" ]]; then
        display+=" \e[38;5;240m(\e[0m\e[38;5;245m↻ ${session_reset_formatted}\e[0m\e[38;5;240m)\e[0m"
    fi
    display+=" \e[38;5;240m│\e[0m"
    display+=" \e[38;5;246mWeek:\e[0m ${week_color}${week_pct}%\e[0m"
    if [[ -n "$week_reset_formatted" ]]; then
        display+=" \e[38;5;240m(\e[0m\e[38;5;245m↻ ${week_reset_formatted}\e[0m\e[38;5;240m)\e[0m"
    fi
    display+=" \e[38;5;240m│\e[0m"
    display+=" \e[38;5;240m↻ ${age}\e[0m"

    echo -e "$display"
}

# Smart path truncation: max 3 components, ~ for home, .. when truncated
truncate_path() {
    local p="${1/#$HOME/\~}"
    local trimmed="${p#/}"
    local parts=() IFS='/'
    read -ra parts <<< "$trimmed"
    local n=${#parts[@]}
    if (( n > 3 )); then
        echo "../${parts[*]: -3}" | tr ' ' '/'
    else
        echo "$p"
    fi
}

# Format directory display with project/current labels
format_directory() {
    local current=$(truncate_path "$1")
    local project=$(truncate_path "$2")

    if [[ "$current" == "$project" ]]; then
        # Same directory: show only project
        echo "\e[38;5;117mproject:\e[0m \e[38;5;117m$project\e[0m"
    else
        # Different directories: show both
        echo "\e[38;5;117mproject:\e[0m \e[38;5;117m$project\e[0m \e[38;5;240m│\e[0m \e[38;5;87mcurrent:\e[0m \e[38;5;87m$current\e[0m"
    fi
}

# Trigger background refresh if needed
trigger_refresh

git_branch=$(get_git_branch)
formatted_session_duration=$(format_duration "$duration_ms")
formatted_lines=$(format_lines "$lines_added" "$lines_removed")
token_warning=$(format_token_warning "$exceeds_tokens")
formatted_model=$(format_model "$model_name")
formatted_cost=$(format_cost "$total_cost")
formatted_ctx_usage=$(format_ctx_usage)
formatted_dir=$(format_directory "$workspace_current_dir" "$workspace_project_dir")
formatted_usage=$(format_usage_display)

# Format and display the status line with two lines
# Line 1: Model, cost, dir, branch, lines, duration
line1="\e[38;5;240m┌─\e[0m $formatted_model $formatted_cost \e[38;5;240m│\e[0m $formatted_dir"
if [[ -n "$git_branch" ]]; then
    line1+=" \e[38;5;240m│\e[0m \e[38;5;208m$git_branch\e[0m"
fi
if [[ -n "$formatted_lines" ]]; then
    line1+=" \e[38;5;240m│\e[0m $formatted_lines"
fi
line1+=" \e[38;5;240m│\e[0m \e[38;5;246m$formatted_session_duration\e[0m"

# Line 2: Context, usage
line2="\e[38;5;240m└─\e[0m $formatted_ctx_usage"
line2+="$token_warning$formatted_usage \e[38;5;240m─┘\e[0m"

echo -e "$line1"
echo -e "$line2"
