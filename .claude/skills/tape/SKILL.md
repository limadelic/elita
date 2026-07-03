---
name: tape
description: Record and replay agent tests via cassettes. Use when taping a new problem/speck test, re-recording a failed cassette, or verifying a recording is real.
---

# Tape

Cassettes = sparse-matched {q,a} JSON in test/cassettes/. Record once live, replay free forever. The tape IS the spec — edit the cassette, never burn repeated live runs.

## Mechanics

- Test file setup: `LIVE=1`, `CASSETTE=<name>`, TAPE defaults to `replay`. One file per problem.
- Record: `TAPE=rec mix test --include live <file>:<line>` → appends to test/cassettes/<name>.json
- Replay: plain `mix test --include live <file>` — no TAPE. Deterministic, seconds, free.
- test_helper starts Tape.Writer, max_cases 1. Replay matches agent tag + sparse content; turn count is tiebreak.

## Recording runbook

1. **Clean cassette first.** Failed/killed runs poison it: `git checkout -- test/cassettes/<name>.json`
2. **Budget timeouts before firing.** ExUnit `@tag timeout` must exceed any internal poll bound (tag 1_200_000 / poll 1150s worked for napo). A red "Timeout after Ns" usually means bound too short, not a bug — check the log for healthy progress before touching code.
3. **Fire detached, never block:**
   `nohup env TAPE=rec mix test --include live <file>:<line> > <scratch>/<name>.log 2>&1 &`
4. **Poll, don't stare.** Repeat plain checks: `grep -A1 "Finished in" <log> || ls -l <log>`. Output arrives in multi-minute BURSTS — a static log is NORMAL. Kill ONLY if the pid is dead or the log mtime (`stat -f "%Sm"`) is 15+ min stale.
5. **Never ask a blocked agent from the test** — `ask :napo` deadlocks when napo asks children. Use tell-and-poll: `tell` then poll ETS/mem for the done marker.

## After green

1. **Hollow-green audit — a fast green is suspect until proven:**
   - `git diff --stat test/cassettes/<name>.json` — real new lines?
   - `git diff <cassette> | grep -o '"agent": *"[a-z_]*"' | sort | uniq -c` — expected agents present?
   - Log shows real work (splits, attempts, judge verdicts)?
2. **Replay verify once**: run the whole file off tape, expect green in seconds. One verification per change — no redundant runs.
3. **Gate + commit together**: `mix test --include live` (full suite, all replay) + `mix credo --strict` both clean, then commit test file + cassette in one commit, push.

## Never

- Re-run live what's already recorded.
- Record over a dirty cassette.
- Trust green without the audit.
- Sleep/loop while waiting — detached run + repeated cheap checks.
