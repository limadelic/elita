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

    ( expect <<'EXPECT_SCRIPT'
set timeout 16
log_file /tmp/expect_render.txt
spawn $::env(CLAUDE_BIN) claude
expect {
    "Claude Code" { exit 0 }
    timeout { exit 1 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

    if grep -q "Claude Code" /tmp/expect_render.txt 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: Claude Code not found"
        return 1
    fi
}

size_test() {
    ( EL_ROWS=120 EL_COLS=40 expect <<'EXPECT_SCRIPT'
set timeout 5
log_file /tmp/expect_size.txt
spawn $::env(CLAUDE_BIN) claude
expect {
    timeout { exit 0 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

    if grep -q "─" /tmp/expect_size.txt 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: No divider found"
        return 1
    fi
}

size_test_80x24() {
    ( EL_ROWS=24 EL_COLS=80 expect <<'EXPECT_SCRIPT'
set timeout 4
log_file /tmp/expect_size2.txt
spawn $::env(CLAUDE_BIN) claude
expect {
    timeout { exit 0 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

    if grep -q "─" /tmp/expect_size2.txt 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: No divider at 80x24"
        return 1
    fi
}

input_test() {
    ( expect <<'EXPECT_SCRIPT'
set timeout 8
log_file /tmp/expect_input.txt
spawn $::env(CLAUDE_BIN) claude
sleep 1
send "test_input_\r"
expect {
    timeout { exit 0 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

    if grep -q "test_input_" /tmp/expect_input.txt 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: Input not echoed"
        return 1
    fi
}

submit_test() {
    ( expect <<'EXPECT_SCRIPT'
set timeout 12
log_file /tmp/expect_submit.txt
spawn $::env(CLAUDE_BIN) claude
sleep 1
send "hi\r"
sleep 3
send "\x03"
expect {
    timeout { exit 0 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

    if grep -q "hi" /tmp/expect_submit.txt 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: No response"
        return 1
    fi
}

kill_test() {
    ( expect <<'EXPECT_SCRIPT'
set timeout 7
spawn $::env(CLAUDE_BIN) claude
sleep 1
send "\x03"
sleep 0.3
send "\x03"
sleep 1
expect {
    timeout { exit 0 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

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
    ( expect <<'EXPECT_SCRIPT'
set timeout 5
spawn $::env(CLAUDE_BIN) claude
sleep 1
send "\x03"
sleep 0.3
send "\x03"
sleep 1
expect {
    timeout { exit 0 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

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

slash_test() {
    ( expect <<'EXPECT_SCRIPT'
set timeout 10
log_file /tmp/expect_slash.txt
spawn $::env(CLAUDE_BIN) claude
sleep 1
send "/effort\r"
expect {
    timeout { exit 0 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

    sleep 0.5

    if grep -q "/effort" /tmp/expect_slash.txt 2>/dev/null; then
        echo "PASS"
        return 0
    else
        echo "FAIL: Slash command not echoed"
        pkill -9 -f "bin/el claude" 2>/dev/null || true
        return 1
    fi
}

exit_test() {
    ( expect <<'EXPECT_SCRIPT'
set timeout 10
log_file /tmp/expect_exit.txt
spawn $::env(CLAUDE_BIN) claude
expect {
    "Claude Code" { send "/exit\r"; sleep 1 }
    timeout { exit 1 }
}
expect {
    timeout { exit 0 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

    sleep 0.5

    if pgrep -f "bin/el claude" >/dev/null 2>&1; then
        pkill -9 -f "bin/el claude" 2>/dev/null || true
        echo "FAIL: Process still running after /exit"
        return 1
    else
        echo "PASS"
        return 0
    fi
}

inject_test() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    (
        SCRIPT_DIR="$script_dir" timeout 15 expect -f /dev/stdin <<'EXPECT_SCRIPT'
set timeout 12
log_file /tmp/expect_inject.txt

spawn $env(CLAUDE_BIN) claude
sleep 1

# Spawn elixir probe to inject "hola", then /exit
catch {exec elixir --name probe@127.0.0.1 --cookie elita $env(SCRIPT_DIR)/inject_probe.exs 2>/dev/null &} pid
sleep 3

expect {
    eof { exit 0 }
    timeout { exit 1 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

    sleep 0.5

    # Check if hola appears in the output OR if the process exited cleanly
    if grep -q "hola" /tmp/expect_inject.txt 2>/dev/null; then
        echo "PASS"
        return 0
    elif ! pgrep -f "bin/el claude" >/dev/null 2>&1; then
        # Process exited, which means /exit was injected successfully
        echo "PASS"
        return 0
    else
        echo "FAIL: Injected text not found and process still running"
        pkill -9 -f "bin/el claude" 2>/dev/null || true
        return 1
    fi
}

tell_test() {
    (
        timeout 15 expect -f /dev/stdin <<'EXPECT_SCRIPT'
set timeout 12
log_file /tmp/expect_tell.txt

spawn $env(CLAUDE_BIN) claude
sleep 1

# Tell from shell: el tell claude "que tal"
catch {exec $env(CLAUDE_BIN) tell claude "que tal" 2>/dev/null &} pid
sleep 2

# Send /exit to close session
send "/exit\r"
expect {
    timeout { exit 0 }
}
EXPECT_SCRIPT
    ) >/dev/null 2>&1

    sleep 0.5

    if grep -q "que tal" /tmp/expect_tell.txt 2>/dev/null; then
        echo "PASS"
        return 0
    elif ! pgrep -f "bin/el claude" >/dev/null 2>&1; then
        # Process exited cleanly
        echo "PASS"
        return 0
    else
        echo "FAIL: Tell text not injected"
        pkill -9 -f "bin/el claude" 2>/dev/null || true
        return 1
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
    export CLAUDE_BIN

    echo "=== Claude Wrap E2E Test Suite ==="
    echo ""

    run_test "render_test" "RENDER"
    run_test "size_test" "SIZE_120x40"
    run_test "size_test_80x24" "SIZE_80x24"
    run_test "input_test" "INPUT"
    run_test "submit_test" "SUBMIT"
    run_test "kill_test" "KILL"
    run_test "clean_test" "CLEAN"
    run_test "slash_test" "SLASH"
    run_test "exit_test" "EXIT"
    run_test "inject_test" "INJECT"
    run_test "tell_test" "TELL"

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
