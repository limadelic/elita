#!/bin/sh
# usage: ops/money/check.sh [command...]   (default: mix test)
# reads month-to-date API spend, runs the command, reads again, fails on any delta

key="${ANTHROPIC_ADMIN_KEY}"
if [ -z "$key" ]; then
  echo "ANTHROPIC_ADMIN_KEY not set. Create at: console.anthropic.com → Settings → Admin keys" >&2
  exit 1
fi

month=$(date -u +%Y-%m-01T00:00:00Z)

spend() {
  curl -sf "https://api.anthropic.com/v1/organizations/cost_report?starting_at=$month" \
    -H "x-api-key: $key" -H "anthropic-version: 2023-06-01" |
    ruby -rjson -e 'puts JSON.parse($stdin.read)["data"].to_a.sum { |b| b["results"].to_a.sum { |r| r["amount"].to_f } }'
}

before=$(spend) || exit 1
echo "money before: \$$before"

if [ $# -eq 0 ]; then
  mix test
else
  "$@"
fi
code=$?

after=$(spend) || exit 1
echo "money after:  \$$after"

delta=$(ruby -e "puts ARGV[1].to_f - ARGV[0].to_f" "$before" "$after")
if [ "$(ruby -e "puts ARGV[0].to_f > 0 ? 1 : 0" "$delta")" = "1" ]; then
  echo "MONEY SPENT: \$$delta"
  exit 1
fi

echo "money spent: \$0"
exit $code
