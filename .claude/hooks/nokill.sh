#!/usr/bin/env bash
# Blocks kill/pkill/killall from being run OR written into the code.
# kill -9 -1 from pty cleanup shot the boss machine 4 times on 2026-08-03.

payload=$(cat)
tool=$(printf '%s' "$payload" | jq -r '.tool_name // ""')

case "$tool" in
  Bash) text=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""') ;;
  *)    text=$(printf '%s' "$payload" | jq -r '[.tool_input.content, .tool_input.new_string, (.tool_input.edits//[]|map(.new_string)|join("\n"))] | map(select(.!=null)) | join("\n")') ;;
esac

if printf '%s' "$text" | grep -Eq '(^|[^[:alnum:]_.-])(kill|pkill|killall)([^[:alnum:]_-]|$)'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "BLOCKED: kill/pkill/killall is banned in this lane. kill -9 -1 wiped the boss machine 4 times. Use OTP teardown: :erlang.monitor(:port, p) + :erlang.port_close(p) + bounded receive."
    },
    systemMessage: "nokill hook: blocked a kill"
  }'
  exit 0
fi

exit 0
