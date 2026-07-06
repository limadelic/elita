#!/bin/bash

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
    pkill -9 -f "bin/el claude" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

TEMP_DIR=$(mktemp -d)

render_test() {
    local output_file="$TEMP_DIR/render.txt"

    expect -c "
        set timeout 16
        log_file $output_file
        spawn $CLAUDE_BIN claude
        expect {
            \"Claude Code\" { exit 0 }
            timeout { exit 1 }
        }
    " 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "PASS"
        return 0
    else
        echo "FAIL: Claude Code not found"
        return 1
    fi
}

size_test() {
    local output_file="$TEMP_DIR/size_120x40.txt"

    EL_ROWS=120 EL_COLS=40 expect -c "
        set timeout 5
        log_file $output_file
        spawn $CLAUDE_BIN claude
        expect {
            timeout { exit 0 }
        }
    " 2>/dev/null

    if grep -q "─" "$output_file" 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: No divider found"
        return 1
    fi
}

size_test_80x24() {
    local output_file="$TEMP_DIR/size_80x24.txt"

    EL_ROWS=24 EL_COLS=80 expect -c "
        set timeout 4
        log_file $output_file
        spawn $CLAUDE_BIN claude
        expect {
            timeout { exit 0 }
        }
    " 2>/dev/null

    if grep -q "─" "$output_file" 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: No divider at 80x24"
        return 1
    fi
}

input_test() {
    local output_file="$TEMP_DIR/input.txt"

    expect -c "
        set timeout 8
        log_file $output_file
        spawn $CLAUDE_BIN claude
        sleep 1
        send \"hello\r\"
        expect {
            timeout { exit 0 }
        }
    " 2>/dev/null

    if grep -q "hello" "$output_file" 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: Input not echoed"
        return 1
    fi
}

submit_test() {
    local output_file="$TEMP_DIR/submit.txt"

    expect -c "
        set timeout 12
        log_file $output_file
        spawn $CLAUDE_BIN claude
        sleep 1
        send \"hi\r\"
        sleep 3
        send \"\x03\"
        expect {
            timeout { exit 0 }
        }
    " 2>/dev/null

    if grep -q "hi" "$output_file" 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: No response"
        return 1
    fi
}

kill_test() {
    expect -c "
        set timeout 7
        spawn $CLAUDE_BIN claude
        sleep 1
        send \"\x03\"
        sleep 0.3
        send \"\x03\"
        sleep 1
        expect {
            timeout { exit 0 }
        }
    " 2>/dev/null

    sleep 0.3

    if pgrep -f "bin/el claude" >/dev/null 2>&1; then
        pkill -9 -f "bin/el claude" 2>/dev/null || true
        echo "FAIL: Process still running"
        return 1
    else
        echo "PASS"
        return 0
    fi
}

clean_test() {
    expect -c "
        set timeout 5
        spawn $CLAUDE_BIN claude
        sleep 1
        send \"\x03\"
        sleep 0.3
        send \"\x03\"
        sleep 1
        expect {
            timeout { exit 0 }
        }
    " 2>/dev/null

    sleep 0.5

    local orphans=$(ps aux 2>/dev/null | grep -E "bin/el" | grep -v grep | wc -l)

    if [ "$orphans" -gt 0 ]; then
        pkill -9 -f "bin/el" 2>/dev/null || true
        echo "FAIL: Orphan processes found"
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
        echo "✗ $test_name: $output"
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
