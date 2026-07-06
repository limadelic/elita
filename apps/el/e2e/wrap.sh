#!/bin/bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEMP_DIR=""
PASS_COUNT=0
FAIL_COUNT=0
CLAUDE_BIN="$REPO_ROOT/bin/el"

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    pkill -f "bin/el claude" 2>/dev/null || true
    pkill -f "expect" 2>/dev/null || true
    sleep 0.2
}

trap cleanup EXIT INT TERM

TEMP_DIR=$(mktemp -d)

render_test() {
    local output_file="$TEMP_DIR/render.txt"

    # Use expect to run el claude and capture output
    expect <<EOF 2>/dev/null
set timeout 16
spawn -open [open "|$CLAUDE_BIN claude" r+]
expect {
    "Claude Code" {
        puts "PASS"
        exit 0
    }
    timeout {
        puts "FAIL: Claude Code not found within 15s"
        exit 1
    }
}
EOF
    return $?
}

size_test() {
    local rows=120
    local cols=40
    local output_file="$TEMP_DIR/size_120x40.txt"

    # Capture output from el claude with specific size
    expect <<EOF 2>/dev/null >$output_file
set env(EL_ROWS) $rows
set env(EL_COLS) $cols
set timeout 5

spawn $CLAUDE_BIN claude
expect eof

exit 0
EOF

    # Check for divider lines
    local divider_lines=$(grep -E "─{20,}" "$output_file" 2>/dev/null | head -1)

    if [ -z "$divider_lines" ]; then
        echo "FAIL: No divider found"
        return 1
    fi

    echo "PASS"
    return 0
}

size_test_80x24() {
    local rows=24
    local cols=80
    local output_file="$TEMP_DIR/size_80x24.txt"

    expect <<EOF 2>/dev/null >$output_file
set env(EL_ROWS) $rows
set env(EL_COLS) $cols
set timeout 4

spawn $CLAUDE_BIN claude
expect eof

exit 0
EOF

    local divider_lines=$(grep -E "─{20,}" "$output_file" 2>/dev/null | head -1)

    if [ -z "$divider_lines" ]; then
        echo "FAIL: No divider found at ${rows}x${cols}"
        return 1
    fi

    echo "PASS"
    return 0
}

input_test() {
    local output_file="$TEMP_DIR/input.txt"

    expect <<EOF 2>/dev/null >$output_file
set timeout 8

spawn $CLAUDE_BIN claude
expect {
    "input" {
        send "test_echo\r"
        expect eof
    }
    timeout {
        send "test_echo\r"
        expect eof
    }
}

exit 0
EOF

    if grep -q "test_echo" "$output_file" 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: Input not echoed"
        return 1
    fi
}

submit_test() {
    local output_file="$TEMP_DIR/submit.txt"

    expect <<EOF 2>/dev/null >$output_file
set timeout 12

spawn $CLAUDE_BIN claude
expect {
    "input" {
        send "hi\r"
        expect {
            -re "⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|Sending|sending|Error" {
                send "\x03"
                expect eof
            }
            timeout {
                send "\x03"
                expect eof
            }
        }
    }
    timeout {
        send "hi\r"
        sleep 2
        send "\x03"
        expect eof
    }
}

exit 0
EOF

    # Check for any response indicators
    if grep -qE "⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|Sending|sending|Error|hi" "$output_file" 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: No response detected"
        return 1
    fi
}

kill_test() {
    local output_file="$TEMP_DIR/kill.txt"
    local start=$(date +%s)

    expect <<EOF 2>/dev/null >$output_file
set timeout 7

spawn $CLAUDE_BIN claude
expect {
    timeout {
        send "\x03"
        sleep 0.5
        send "\x03"
        sleep 1
        expect eof
    }
}

exit 0
EOF

    # Check process is gone
    if pgrep -f "bin/el claude" >/dev/null 2>&1; then
        echo "FAIL: Process still running"
        return 1
    else
        echo "PASS"
        return 0
    fi
}

clean_test() {
    local output_file="$TEMP_DIR/clean.txt"

    expect <<EOF 2>/dev/null >$output_file
set timeout 5

spawn $CLAUDE_BIN claude
expect {
    timeout {
        send "\x03"
        sleep 0.3
        send "\x03"
        expect eof
    }
}

exit 0
EOF

    sleep 0.5

    # Check for orphan processes
    local orphans=$(ps aux 2>/dev/null | grep -E "bin/el" | grep -v grep | wc -l)

    if [ "$orphans" -gt 0 ]; then
        pkill -9 -f "bin/el" 2>/dev/null || true
        echo "FAIL: Found orphan processes"
        return 1
    else
        echo "PASS"
        return 0
    fi
}

run_test() {
    local test_func=$1
    local test_name=$2

    local output
    output=$($test_func 2>&1)
    local exit_code=$?

    if echo "$output" | grep -q "^PASS"; then
        echo "✓ $test_name: $output"
        ((PASS_COUNT++))
        return 0
    else
        echo "✗ $test_name"
        if [ -n "$output" ]; then
            echo "  $output"
        fi
        ((FAIL_COUNT++))
        return 1
    fi
}

main() {
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
        echo "All tests PASSED ✓"
        return 0
    else
        echo "Some tests FAILED"
        return 1
    fi
}

main
