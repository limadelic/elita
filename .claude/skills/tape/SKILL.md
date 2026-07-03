---
name: tape
description: Record and replay agent tests via cassettes. Use when taping a test, re-recording a failed cassette, or verifying a recording.
---

# Tape

Record once live, replay free forever. The tape IS the spec — edit the cassette, never re-run live what's recorded.

## Record

1. Clean cassette first — failed runs poison it: `git checkout -- test/cassettes/<name>.json`
2. Budget timeouts: `@tag timeout` must exceed any poll bound inside the test. A red "Timeout after Ns" with healthy log = bound too short, not a bug.
3. Never `ask` an agent that asks others — deadlock. `tell` then poll mem for the done marker.
4. Fire detached, never block: `nohup env TAPE=rec mix test --include live <file>:<line> > <scratch>/<name>.log 2>&1 &`
5. Poll `grep -A1 "Finished in" <log>` — output bursts, static log is NORMAL. Kill only if pid dead or log mtime 15+ min stale.

## After green

1. Fast green is suspect — audit: `git diff --stat` the cassette, expected agents in new entries (`grep -o '"agent": *"[a-z_]*"' | sort | uniq -c`), real work in the log.
2. Replay whole file off tape once — green in seconds.
3. Commit test + cassette together. Gates: full `mix test --include live` + `mix credo --strict` at zero.
