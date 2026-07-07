#!/bin/bash

SESSION_NAME="${1:-dude}"
EL_BIN="${2:-bin/el}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"

cd "$REPO_ROOT"

# Boot el claude as distributed node on 127.0.0.1
export EL_HOST=127.0.0.1

# Run el claude in background, keeping stdin as /dev/null
nohup "$EL_BIN" claude "$SESSION_NAME" < /dev/null > /tmp/puppet_session_$SESSION_NAME.log 2>&1 &

# Give the node time to start and register itself
sleep 2
exit 0
