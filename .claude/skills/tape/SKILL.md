---
name: tape
description: Record and replay agent tests via cassettes. Use when taping a test, re-recording a failed cassette, or verifying a recording.
---

# Tape

Record once live, replay free forever. The tape IS the spec — edit the cassette, never re-run live what's recorded.

1. Clean cassette first: `git checkout -- test/cassettes/<name>.json`
2. Fire detached: `nohup env TAPE=rec mix test --include live <file>:<line> > <scratch>/<name>.log 2>&1 &`
3. Poll `grep -A1 "Finished in" <log>` — output bursts, static log is normal. Kill only if pid dead or mtime 15+ min stale.
4. Green? Audit before trusting: `git diff --stat` the cassette, expected agents in new entries, real work in the log.
5. Replay once off tape, then commit test + cassette together. Gates: full `mix test --include live` + `mix credo --strict`.
