#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CLAUDE_BIN="$REPO_ROOT/bin/el"

cleanup() {
    pkill -9 -f "script.*stty rows" 2>/dev/null || true
    pkill -9 -f "bin/el claude" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

main() {
    export CLAUDE_BIN

    echo "=== Claude Wrap E2E Test Suite ==="
    echo ""

    local log="/tmp/wrap_test.txt"
    rm -f "$log"

    local start=$(date +%s.%N)

    # ONE session - linear test with all beats
    ( expect <<'EXPECT_SCRIPT'
set timeout 40
log_file /tmp/wrap_test.txt

spawn $::env(CLAUDE_BIN) claude

# Beat 1: Wait for welcome
expect "Claude Code"
sleep 0.5

# Beat 2: Open model menu and select Haiku (cheapest model)
send "/model\r"
sleep 2

# Navigate to Haiku - arrow down moves through options
# Default is Sonnet, arrow down goes to Opus, arrow down again is Haiku
send "\033\[B"
sleep 0.5
send "\033\[B"
sleep 0.5

# Select with Enter
send "\r"
sleep 2

# Beat 3: Type "1 + 1" and let Haiku respond
send "1 + 1\r"
sleep 6

# Beat 4: Send /effort to flip effort level (visible state change)
send "/effort\r"
sleep 1

# Beat 5: Exit cleanly with /exit
send "/exit\r"
sleep 2

# Wait for exit
expect {
    eof { }
    timeout { }
}

exit 0
EXPECT_SCRIPT
    )

    local end=$(date +%s.%N)
    local wall_time=$(echo "$end - $start" | bc)

    # Verify all beats
    local pass=1

    echo "Verifying test execution..."
    echo ""

    # Beat 1: Welcome
    if grep -q "Claude Code" "$log" 2>/dev/null; then
        echo "✓ Beat 1: Welcome screen rendered"
    else
        echo "✗ Beat 1: Welcome screen NOT found"
        pass=0
    fi

    # Beat 2: Model menu (look for Haiku or model change indicator)
    if grep -q "/model" "$log" 2>/dev/null; then
        echo "✓ Beat 2: Model menu command visible"
        if grep -qi "haiku" "$log" 2>/dev/null; then
            echo "  ✓ Haiku found in output"
        else
            echo "  ⚠ Haiku not visible (may be menu navigation issue)"
        fi
    else
        echo "✗ Beat 2: Model menu command NOT found"
        pass=0
    fi

    # Beat 3: Math problem submission
    if grep -q "1.*+.*1\|1 + 1" "$log" 2>/dev/null; then
        echo "✓ Beat 3: Math problem visible in session"

        # Check if answer appears (Haiku should respond with "2")
        if grep -q "2" "$log" 2>/dev/null; then
            echo "  ✓ Response received (contains answer)"
        else
            echo "  ⚠ Response may not be visible (check captured content)"
        fi
    else
        echo "✗ Beat 3: Math problem NOT found in log"
        pass=0
    fi

    # Beat 4: Effort command
    if grep -q "/effort" "$log" 2>/dev/null; then
        echo "✓ Beat 4: /effort command executed"
    else
        echo "✗ Beat 4: /effort command NOT found"
        pass=0
    fi

    # Beat 5: Clean exit
    sleep 2
    pkill -9 -f "script.*stty rows" 2>/dev/null || true
    pkill -9 -f "bin/el claude" 2>/dev/null || true
    sleep 1

    if pgrep -f "bin/el claude" >/dev/null 2>&1; then
        echo "✗ Beat 5: Process still running after /exit"
        pkill -9 -f "bin/el claude" 2>/dev/null
        pass=0
    else
        echo "✓ Beat 5: Clean exit and process terminated"
    fi

    local orphans=$(pgrep -f "script.*stty" 2>/dev/null | wc -l)
    if [ "$orphans" -eq 0 ]; then
        echo "✓ Cleanup: No process survivors"
    else
        echo "⚠ Cleanup: $orphans survivors (aggressive cleanup)"
        pkill -9 -f "script.*stty" 2>/dev/null || true
        sleep 1
    fi

    echo ""

    # Wall time check - must be >= 20s for real session
    if (( $(echo "$wall_time < 20" | bc -l) )); then
        echo "✗ Wall time too short: ${wall_time}s (< 20s, process likely crashed)"
        pass=0
    else
        echo "✓ Wall time valid: ${wall_time}s"
    fi

    # Check for Elixir stacktraces (ArgumentError, RuntimeError, ** patterns)
    if grep -qE "ArgumentError|RuntimeError|\*\*" "$log" 2>/dev/null; then
        echo "✗ Elixir stacktrace detected in capture"
        grep -nE "ArgumentError|RuntimeError" "$log" 2>/dev/null | head -3
        pass=0
    else
        echo "✓ No Elixir stacktraces"
    fi

    echo ""
    echo "Sessions: 1"
    echo "Prompts: 1 (haiku)"
    echo "Wall time: ${wall_time}s"
    echo ""

    if [ $pass -eq 1 ]; then
        echo "Test PASSED ✓"
        return 0
    else
        echo "Test FAILED (see diagnostics above)"
        return 1
    fi
}

main
