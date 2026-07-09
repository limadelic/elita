---
name: tape
description: Record and replay agent tests via cassettes. Use when taping a test, re-recording a failed cassette, or verifying a recording.
---

# Tape

Record once live, replay free forever. The tape IS the spec — edit the cassette, don't re-record.

## Targets

- **Test files** (`test/` .exs): Unit/integration tests via Tester
- **Features** (`features/` .feature): Acceptance flows via Gherkin/Cucumber, one cassette per feature or Examples row

## Run

- `mix test` — replay from cassettes, free, seconds
- `mix tape [file:line]` — record (`TAPE=rec mix test`)
- `TAPE=replay bundle exec cucumber` — features, replay from cassettes, $0
- `bundle exec cucumber --dry-run` — list feature scenarios without executing
- `mix live [file:line]` — real API, no tape (`LIVE=1 mix test`)
- `:live`-tagged tests only run when `LIVE=1` — so recording needs `TAPE=rec mix test --include live <file>:<line>`
- `MATCHER=relaxed` loosens cassette matching

## Test file

- `use Tester`, setup: `put_env("TAPE", "replay")` + `put_env("CASSETTE", "<name>")`, on_exit deletes both, `spawn :<agent>`
- Cassette lands in `test/cassettes/<name>.json`
- Helpers: `spawn`, `tell`, `ask`, `verify`, `judge`, `wait_until`, `speck`, `spawned`
- `@tag timeout` must exceed any poll bound — red "Timeout after Ns" with healthy log = bound too short, not a bug
- `ask` on agent asking others deadlocks — `tell` then poll mem for done marker
- Taping napo: [napo.md](napo.md)

## Feature cassettes

- **Cassette resolution**: `@tape:<name>` tag > Examples row `cassette` column > feature filename
- Cassettes land in `test/cassettes/<feature-name>.json`
- For Scenario Outlines: one Examples row per cassette, record by line number for isolation
- Verify cassette lands in RIGHT file — don't touch neighbors

## Record

### Tests
- Clean cassette: `git checkout -- test/cassettes/<name>.json`
- Never record over dirty cassette — `mv test/cassettes/<name>.json /tmp/<name>-backup.json` first
- Fire detached: `nohup env TAPE=rec mix test --include live <file>:<line> > <scratch>/<name>.log 2>&1 &`
- Poll log: `grep -A1 "Finished in" <log>` — output bursts, static log is NORMAL

### Features
- Recordings are long and billed — fire nohup detached with log in scratchpad, return immediately
- `nohup env TAPE=rec bundle exec cucumber features/foo.feature:<line> > <scratch>/<name>.log 2>&1 &`
- Replay is $0 and sub-second — always default to replay after recording verified

## Retaping (Approval Testing)

Agents are nondeterministic: fresh recordings phrase/name things differently, sometimes skip steps.

- **Preserve structure**: Same scenario shape, same rows, same story beats — never rewrite to match a tape
- **Adjust text**: After retaping, update fragment text to new tape VERBATIM (case-insensitive match is key)
- **Golden master**: Feature file = spec + regression net; new tape ≈ new golden master for approval
- **Lost story beats**: If new tape skipped a beat (e.g., speck omitted reading agent def), consider re-recording once — runs vary
- **Specks extra volatile**: @tag speck scenarios expect EVERY retape to need fragment approval; preserve emoji rows (🧪 🤖 🎭 ✏️ 🚀 📢 ✨)

## Green

- Fast green is suspect — `git diff --stat` cassette, check agents in entries, real work in log
- Replay whole file off tape once — green in seconds
- Commit test/feature + cassette together, gates green: `mix test` + `mix lint`

## Silent failures (Replay)

Replay dies silently on tape miss: if dispatched message doesn't match next taped exchange for that agent, el process dies.

- **Symptom**: Closed-stream IOError from pty harness, not an error message
- **Debug**: Diff what got dispatched vs taped q (q.messages = per-agent history)
- **Check**: Tells dispatch "[from sender] message"; n counters are framework-generated

## NEVER

- Never re-run live what's recorded
- Never record over a dirty cassette (mv to /tmp first)
- Never append to existing cassette with TAPE=rec (stale exchanges hit replay first)
- Never block/sleep waiting — detached run, cheap polls
- Never kill a run unless pid dead or log mtime 15+ min stale
- Never trust green without the audit
