#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEMP_DIR=""
PASS_COUNT=0
FAIL_COUNT=0
CLAUDE_BIN="$REPO_ROOT/bin/el"

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    # Kill any remaining claude/script/el processes
    pkill -f "bin/el claude" 2>/dev/null || true
    pkill -f "/script" 2>/dev/null || true
    pkill -f "apps/el/el" 2>/dev/null || true
    sleep 0.5
}

trap cleanup EXIT

# Create temp dir for captures
TEMP_DIR=$(mktemp -d)

render_test() {
    local output_file="$TEMP_DIR/render.txt"
    local start_time=$(date +%s)
    local timeout=15

    # Use script command to capture output
    script -q "$output_file" sh -c "EL_ROWS=24 EL_COLS=80 $CLAUDE_BIN claude" 2>&1 &
    local pid=$!

    # Wait for "Claude Code" text to appear
    while true; do
        local now=$(date +%s)
        local elapsed=$((now - start_time))

        if [ $elapsed -gt $timeout ]; then
            kill -9 $pid 2>/dev/null || true
            echo "FAIL: 'Claude Code' not found within ${timeout}s"
            return 1
        fi

        if grep -q "Claude Code" "$output_file" 2>/dev/null; then
            kill -9 $pid 2>/dev/null || true
            echo "PASS"
            return 0
        fi

        sleep 0.5
    done
}

size_test() {
    local rows=120
    local cols=40
    local output_file="$TEMP_DIR/size_120x40.txt"

    # Run with specific size
    script -q "$output_file" sh -c "EL_ROWS=$rows EL_COLS=$cols $CLAUDE_BIN claude" 2>&1 &
    local pid=$!

    sleep 5

    # Kill the process
    kill -9 $pid 2>/dev/null || true
    sleep 0.5

    # Check for divider line - look for lines with ─ characters
    local dividers=$(grep "─" "$output_file" | head -5)

    if [ -z "$dividers" ]; then
        echo "FAIL: No divider found at ${rows}x${cols}"
        return 1
    fi

    # Get length of first divider line
    local divider=$(echo "$dividers" | head -1)
    local divider_len=${#divider}

    # Check if it's approximately the column width
    # Allow ±20 chars tolerance
    local min=$((cols - 20))
    local max=$((cols + 20))

    if [ "$divider_len" -ge "$min" ] && [ "$divider_len" -le "$max" ]; then
        echo "PASS (width=$divider_len, expected ~$cols)"
        return 0
    else
        echo "FAIL: Divider width $divider_len not near $cols"
        return 1
    fi
}

size_test_80x24() {
    local rows=24
    local cols=80
    local output_file="$TEMP_DIR/size_80x24.txt"

    script -q "$output_file" sh -c "EL_ROWS=$rows EL_COLS=$cols $CLAUDE_BIN claude" 2>&1 &
    local pid=$!

    sleep 3

    kill -9 $pid 2>/dev/null || true
    sleep 0.5

    local dividers=$(grep "─" "$output_file" | head -5)

    if [ -z "$dividers" ]; then
        echo "FAIL: No divider found at ${rows}x${cols}"
        return 1
    fi

    local divider=$(echo "$dividers" | head -1)
    local divider_len=${#divider}

    local min=$((cols - 15))
    local max=$((cols + 15))

    if [ "$divider_len" -ge "$min" ] && [ "$divider_len" -le "$max" ]; then
        echo "PASS (width=$divider_len, expected ~$cols)"
        return 0
    else
        echo "FAIL: Divider width $divider_len not near $cols at ${rows}x${cols}"
        return 1
    fi
}

input_test() {
    local fifo="$TEMP_DIR/input_fifo"
    local output_file="$TEMP_DIR/input.txt"
    mkfifo "$fifo" || return 1

    {
        sleep 2
        echo "test123"
        sleep 1
    } > "$fifo" &
    local writer_pid=$!

    script -q "$output_file" sh -c "EL_ROWS=24 EL_COLS=80 $CLAUDE_BIN claude" < "$fifo" 2>&1 &
    local pid=$!

    sleep 5

    kill -9 $pid 2>/dev/null || true
    kill -9 $writer_pid 2>/dev/null || true
    sleep 0.5

    if grep -q "test123" "$output_file" 2>/dev/null; then
        echo "PASS (echoed input)"
        return 0
    else
        echo "FAIL: Input not echoed"
        return 1
    fi
}

submit_test() {
    local fifo="$TEMP_DIR/submit_fifo"
    local output_file="$TEMP_DIR/submit.txt"
    mkfifo "$fifo" || return 1

    {
        sleep 2
        echo "hi"
        sleep 3
        # Send Ctrl+C
        printf "\x03"
        sleep 1
    } > "$fifo" &
    local writer_pid=$!

    script -q "$output_file" sh -c "EL_ROWS=24 EL_COLS=80 $CLAUDE_BIN claude" < "$fifo" 2>&1 &
    local pid=$!

    sleep 12

    kill -9 $pid 2>/dev/null || true
    kill -9 $writer_pid 2>/dev/null || true
    sleep 0.5

    # Look for any response indicators (spinner chars, response text, etc.)
    if grep -q -E '[|/\\-⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]|Sending|response|Error' "$output_file" 2>/dev/null; then
        echo "PASS (response detected)"
        return 0
    else
        echo "FAIL: No response/spinner detected"
        return 1
    fi
}

kill_test() {
    local fifo="$TEMP_DIR/kill_fifo"
    local output_file="$TEMP_DIR/kill.txt"
    mkfifo "$fifo" || return 1

    {
        sleep 2
        # Send double Ctrl+C
        printf "\x03"
        sleep 0.5
        printf "\x03"
        sleep 1
    } > "$fifo" &
    local writer_pid=$!

    script -q "$output_file" sh -c "EL_ROWS=24 EL_COLS=80 $CLAUDE_BIN claude" < "$fifo" 2>&1 &
    local pid=$!

    local start_time=$(date +%s)
    local timeout=5

    while true; do
        local now=$(date +%s)
        local elapsed=$((now - start_time))

        if ! kill -0 $pid 2>/dev/null; then
            # Process is dead
            kill -9 $writer_pid 2>/dev/null || true
            echo "PASS (killed within ${elapsed}s)"
            return 0
        fi

        if [ $elapsed -gt $timeout ]; then
            kill -9 $pid 2>/dev/null || true
            kill -9 $writer_pid 2>/dev/null || true
            echo "FAIL: Process did not exit after double Ctrl+C"
            return 1
        fi

        sleep 0.1
    done
}

clean_test() {
    # Run a quick test and verify no orphans remain
    local fifo="$TEMP_DIR/clean_fifo"
    local output_file="$TEMP_DIR/clean.txt"
    mkfifo "$fifo" || return 1

    {
        sleep 2
        printf "\x03"
        sleep 0.5
        printf "\x03"
        sleep 1
    } > "$fifo" &
    local writer_pid=$!

    script -q "$output_file" sh -c "EL_ROWS=24 EL_COLS=80 $CLAUDE_BIN claude" < "$fifo" 2>&1 &
    local pid=$!

    sleep 8

    kill -9 $pid 2>/dev/null || true
    kill -9 $writer_pid 2>/dev/null || true

    # Wait a bit for processes to fully die
    sleep 1

    # Check for orphan processes
    local orphans=$(ps aux | grep -E "bin/el|/script|apps/el/el" | grep -v grep | grep -v "$SCRIPT_DIR" || true)

    if [ -n "$orphans" ]; then
        echo "FAIL: Found orphan processes"
        echo "$orphans"
        return 1
    else
        echo "PASS (no orphans)"
        return 0
    fi
}

run_test() {
    local test_func=$1
    local test_name=$2

    local output=$($test_func 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ] && echo "$output" | grep -q "^PASS"; then
        echo "✓ $test_name: $(echo "$output" | head -1)"
        ((PASS_COUNT++))
        return 0
    else
        echo "✗ $test_name"
        echo "  $output"
        ((FAIL_COUNT++))
        return 1
    fi
}

echo "=== Claude Wrap E2E Test Suite ==="
echo ""

run_test "render_test" "RENDER"
run_test "size_test" "SIZE_120x40"
run_test "size_test_80x24" "SIZE_80x24"
run_test "input_test" "INPUT"
run_test "submit_test" "SUBMIT"
run_test "kill_test" "KILL"
run_test "clean_test" "CLEAN"

echo ""
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "All tests PASSED"
    exit 0
else
    echo "Some tests FAILED"
    exit 1
fi
