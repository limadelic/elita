---
name: tape
description: Record and replay agent tests via cassettes. Use when taping a test, re-recording a failed cassette, or verifying a recording.
---

# Tape

Record once live, replay free forever. The tape IS the spec — edit the cassette, don't re-record.

## Run

- `mix test` — replay from cassettes, free, seconds
- `mix tape [file:line]` — record live (`TAPE=rec mix test`)
- `mix live [file:line]` — reality check against the real API, no recording (`LIVE=1 mix test`)
- Live tests need `--include live`; replay is the default everywhere

## Record

- Clean cassette first, failed runs poison it: `git checkout -- test/cassettes/<name>.json`
- Fire detached: `nohup env TAPE=rec mix test --include live <file>:<line> > <scratch>/<name>.log 2>&1 &`
- Poll `grep -A1 "Finished in" <log>` — output bursts, static log is NORMAL
- `@tag timeout` must exceed any poll bound inside the test — red "Timeout after Ns" with healthy log = bound too short, not a bug
- `tell` then poll mem for the done marker — `ask` on an agent that asks others deadlocks

## Green

- Fast green is suspect — `git diff --stat` the cassette, check expected agents in new entries, real work in the log
- Replay the whole file off tape once — green in seconds
- Commit test + cassette together, gates green: `mix test --include live` + `mix credo --strict`

## NEVER

- Never re-run live what's recorded
- Never record over a dirty cassette
- Never block or sleep waiting — detached run, cheap polls
- Never kill a run unless pid dead or log mtime 15+ min stale
- Never trust green without the audit
