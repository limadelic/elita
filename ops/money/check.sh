#!/bin/sh
# usage: ops/money/check.sh [command...]   (default: TAPE=replay mix test)
# detects API spending via network connections

# Determine watched hosts
hosts="api.anthropic.com"
if [ -n "$MLM_HOST" ]; then
  # Strip scheme and port from MLM_HOST
  mlm=$(echo "$MLM_HOST" | sed 's|^[a-z]*://||; s|:.*||')
  hosts="$hosts $mlm"
fi

# Resolve hosts to IPs using ruby
ips=$(ruby -rresolv -e "hosts='$hosts'; hosts.split.each { |h| Resolv.each_address(h) { |a| puts a } }" 2>/dev/null)

# Start command in background
hits_file="/tmp/elita_api_hits_$$"
rm -f "$hits_file"

unset ANTHROPIC_API_KEY

if [ $# -eq 0 ]; then
  TAPE=replay mix test &
else
  "$@" &
fi
pid=$!

# Poll for API connections while command runs
while kill -0 $pid 2>/dev/null; do
  lsof -i -n -P 2>/dev/null | grep ESTABLISHED | grep -E 'beam|erl' | while read line; do
    # Extract peer IP (right side of ->, before :)
    peer=$(echo "$line" | sed -n 's/.*->\([^:]*\).*/\1/p')

    # Check if peer matches any watched IP
    for ip in $ips; do
      if [ "$peer" = "$ip" ]; then
        echo "$line" >> "$hits_file"
        break
      fi
    done
  done
  sleep 1
done

# Wait for background command to fully exit
wait $pid
code=$?

# Report results
if [ -f "$hits_file" ] && [ -s "$hits_file" ]; then
  count=$(wc -l < "$hits_file")
  echo "MONEY: $count API connections detected"
  cat "$hits_file"
  rm -f "$hits_file"
  exit 1
else
  echo "money spent: \$0 (no API connections)"
  rm -f "$hits_file"
  exit $code
fi
