# Root causes (2026-07-04 grounding)

Hard-won lessons. Don't relearn these.

## 1. TapeHandler defaults to live when TAPE unset

**The bug:** TapeHandler.handle defaulted to live fun.() when TAPE env var was nil,
silently making real paid API calls in tests that only set CASSETTE. Non-deterministic
failures got mischaracterized as "pre-existing flaky."

**The fix:** lib/tape_handler.ex: `{"rec",_} -> Tape.Record.handle; {_,"1"} -> live fun.(); default -> Tape.Play.handle.`

**Root cause:** Replay is the safe default. Live should be opt-in (TAPE=rec LIVE=1).

**Mike's signal:** "Root-cause first, never wave off as flaky/pre-existing."

## 2. Application.app_dir(:elita) wrong for dev/umbrella

**The bug:** Application.app_dir(:elita) resolves to _build/.../lib/elita in umbrella
setup, missing agents/ and other source-tree resources.

**The fix:** Reverted to compile-time @app_root = Path.expand("../..", __DIR__).

**Trade-off:** Distribution portability (baking build-machine paths into BEAM bytecode)
is a real concern but deliberately deferred. Revisit when elita ships.

## 3. apps/el/test/test_helper.exs conditional startup fails

**The bug:** Tape.Writer startup was conditional on `if System.get_env("TAPE")` in
test_helper.exs. el_cli_test.exs sets TAPE inside a `setup do` block, which runs
AFTER test_helper.exs already loaded. Tape.Writer never starts.

**The fix:** Start Tape.Writer unconditionally at load.

**Root cause:** Env vars set in `setup do` are too late. Test infrastructure must
load in test_helper.exs, before any test runs.

## 4. Umbrella mix test wall time overhead

**The symptom:** `mix test` from repo root boots BEAM/Mix twice (once per app).
elita ~0.2s, el ~0.03s, but root wall time ~1.5s (boot/compile overhead).

**Status:** No fix applied. Possible future fix: root mix alias running both apps'
tests under one boot. Unstarted, untouched.

**Decision:** It's overhead, not a regression. Don't implement now.
