# Test Debt Plan

## TOP PRIORITY: UNFULFILLED ONE EXTENDED E2E FLOW

The promised single, unified end-to-end test flow was **never built**. Testing strategy called for ONE big flow through address_test covering all features in sequence. Instead, test zoo accumulated—many small isolated tests across separate files.

### Concrete Plan: Build ONE $0-Replay E2E Flow

Single exs file exercising the full feature chain:

1. **Ask routing** — dispatch to named agent via name@path address
2. **Wake on ask** — asleep agent boots session from dormant file when addressed
3. **Tell glob fanout** — tell dispatch targets multiple addresses via glob pattern
4. **Ls path forms** — resolve bare, relative, absolute, glob paths
5. **Cd/standpoint** — change working folder context
6. **Tool prefix** — select harness session (claude vs codex)
7. **Named sessions** — route via naming table
8. **Two-node relay** — peer nodes auto-connect, redial, relay via rpc
9. **Tell-based ask** — answer arrives on ref, no timeout fallback

Constraints:
- `$0 cost replay only` (under 1 second)
- ONE live confirm at the very end
- 60s timeout max
- Extend existing flow (do not add new test files)

---

## Deleted Test Coverage (Now Unrepresented)

Tests removed from wip to enforce discipline. Will be re-integrated into the ONE flow above when e2e is built:

### Removed from apps/el/test:

**address_test.exs** (796 lines) — integration fixtures covering:
- ask with address forms (bare, relative, absolute, unknown, ambiguous, file wake)
- tell-based ask receives reply directly instead of timeout
- tool prefix selects harness session (claude vs codex)
- unknown tool prefix produces instant error
- ls with path forms (bare, relative, absolute, glob)
- ls // shows connected nodes (peer discovery)
- world with injected nodes shows entries
- peers round-trip: record and load (persistence)
- distribution redial connects to loaded peers
- peer node relays via rpc function
- two-node setup and session dispatch
- standpoint cd changes working folder
- named sessions route via routing table
- wake on ask: agent boots from dormant file
- tell glob fanout: dispatch targets multiple addresses
- all features: complete integrated flow (partial)

**ask_test.exs** (44 lines) — routing:
- el routes ask to greet

**daemon_boundary_test.exs** (130 lines) — lifecycle:
- daemon boundary ask/tell lifecycle

**ls_boundary_test.exs** (82 lines) — discovery:
- ls shows local agents
- ls shows remote agents

**puppet_test.exs** (173 lines) — e2e harness:
- puppet e2e: send ask, receive answer

**zombie_test.exs** (45 lines) — e2e harness:
- zombie e2e: spawn session, send ask, exit

**Support files** (boot_session.sh, test_*.exs scaffolding)

### Removed from apps/elita/test:

**live_hook_test.exs** (12 lines):
- live tag in context sets LIVE env var

**tape_handler_test.exs** (33 lines):
- tape handler event processing

**unit/resolver_test.exs** (90 lines):
- name@path parsing and resolution

---

## Baseline Tests (Retained)

27 test files remain covering:

**apps/el:**
- el_cli_test.exs
- pty_test.exs
- el/pty/dsr_test.exs

**apps/elita:**
- napo/contract_test.exs, profit_test.exs
- speck/actor_test.exs, boss_test.exs, doctor_test.exs, greet_test.exs, mother_test.exs, todo_test.exs
- unit: birth_test.exs, boss_test.exs, clock_test.exs, clockwatcher_test.exs, doble9_test.exs, doctor_test.exs, greed_test.exs, greet_test.exs, inbox-triage/triage_test.exs, masked-relay/masked_relay_test.exs, renewal-risk/renewal_risk_test.exs, research-tree/research_test.exs, todo_test.exs, ttt/ttt_test.exs

Test infrastructure (tape library, boot scripts, test helpers) moved to lib — supporting the ONE flow when built.
