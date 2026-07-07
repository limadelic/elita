#!/bin/bash

SESSION_NAME="${1:-dude}"
EL_BIN="${2:-bin/el}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"

cd "$REPO_ROOT"

# Boot el claude as distributed node on 127.0.0.1 under a real PTY via expect
export EL_HOST=127.0.0.1
export EL_BIN
export SESSION_NAME
export LOG_FILE="/tmp/puppet_session_$SESSION_NAME.log"

nohup setsid expect <<'EXPECT_SCRIPT' > /dev/null 2>&1 &
set timeout 999999
log_file $::env(LOG_FILE)
spawn $::env(EL_BIN) claude $::env(SESSION_NAME)
expect eof
EXPECT_SCRIPT

# Give the node time to start and register itself
sleep 2
exit 0
