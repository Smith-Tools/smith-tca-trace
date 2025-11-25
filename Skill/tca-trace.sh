#!/bin/bash
# Smart wrapper for Claude Code skill

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find tca-trace executable
find_tca_trace() {
    if command -v tca-trace >/dev/null 2>&1; then
        command -v tca-trace
    elif [ -x "$SCRIPT_DIR/tca-trace" ]; then
        echo "$SCRIPT_DIR/tca-trace"
    elif [ -x ~/.local/bin/tca-trace ]; then
        echo ~/.local/bin/tca-trace
    elif [ -x /usr/local/bin/tca-trace ]; then
        echo /usr/local/bin/tca-trace
    else
        echo "Error: tca-trace not found" >&2
        exit 1
    fi
}

TCA_TRACE=$(find_tca_trace)

# For skill usage, default to agent mode
if [ -z "$TCA_TRACE_MODE" ]; then
    export TCA_TRACE_MODE="agent"
fi

# Execute with agent-friendly defaults
exec "$TCA_TRACE" "$@" --mode "$TCA_TRACE_MODE"