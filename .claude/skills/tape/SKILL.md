---
name: tape
description: Record and replay agent tests via cassettes. Use when taping a test, re-recording a failed cassette, or verifying a recording.
---

# Tape

Record once live, replay free forever. The tape IS the spec — edit the cassette, don't re-record.

## Run

- `mix test` — replay from cassettes, free, seconds
- `mix tape [file:line]` — record (`TAPE=rec mix test`)
- `mix live [file:line]` — real API, no tape (`LIVE=1 mix test`)
- `:live`-tagged tests only run when `LIVE=1` — so recording one needs `TAPE=rec mix test --include live <file>:<line>`
- `MATCHER=relaxed` loosens cassette matching

## Test file

- `use Tester`, setup: `put_env("TAPE", "replay")` + `put_env("CASSETTE", "<name>")`, on_exit deletes both, `spawn :<agent>`
- Cassette lands in `test/cassettes/<name>.json`
- Helpers from Tester: `spawn`, `tell`, `ask`, `verify`, `judge`, `wait_until`, `speck`, `spawned`
- `@tag timeout` must exceed any poll bound inside the test — red "Timeout after Ns" with healthy log = bound too short, not a bug
- `ask` on an agent that asks others deadlocks — `tell` then poll mem for the done marker

## Record

- Clean cassette first, failed runs poison it: `git checkout -- test/cassettes/<name>.json`
- Fire detached, never block: `nohup env TAPE=rec mix test --include live <file>:<line> > <scratch>/<name>.log 2>&1 &`
- Poll `grep -A1 "Finished in" <log>` — output bursts, static log is NORMAL

## Green

- Fast green is suspect — `git diff --stat` the cassette, check expected agents in new entries, real work in the log
- Replay the whole file off tape once — green in seconds
- Commit test + cassette together, gates green: `mix test` + `mix lint`

## NEVER

- Never re-run live what's recorded
- Never record over a dirty cassette
- Never block or sleep waiting — detached run, cheap polls
- Never kill a run unless pid dead or log mtime 15+ min stale
- Never trust green without the audit
