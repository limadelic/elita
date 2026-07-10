# Platform Assessment: Malko Session-to-Session Puppeteering

## Context
Malko's core job: a session on machine A reliably finds, drives, and observes a session on machine B (via PTY). Tonight's test showed this fails—puppets on ONE machine can't see each other. Cross-machine is the headline capability, not future work.

---

## 1. Distribution Mesh
**Grade: D+ (barely connected, no resilience)**

### What We Have
- `El.Distribution`: boots nodes with hardcoded scheme `claude_<name>@<host>`
- Hardcoded cookie `:elita` (security risk; should be env-based)
- Hardcoded daemon startup on `127.0.0.1` only (localhost-only, blocks multi-machine)
- Manual peer loading from `~/.elita/peers` file (static, no discovery)
- `Node.connect/1` pairwise ad-hoc connections (no mesh guarantee, no retries)
- Default EPMD (Erlang Port Mapper Daemon) for node discovery
- No connection health monitoring or auto-reconnect on partition

### What OTP Gives Free (We Ignore)
- `:net_kernel` can monitor node connections natively (`:nodedown` messages)
- EPMD works fine for LAN; alternative start modes exist (`-start_epmd false` + manual setup)
- libcluster library provides service discovery patterns (mDNS, gossip, static list with health)
- OTP distribution can scale to 1000s of nodes with proper setup
- Connection pooling and retries built into `:rpc` and gen_server calls

### Missing
- **P0: Multi-machine unreachable.** Daemon hardcoded to 127.0.0.1; peers file is manual. No automatic LAN discovery or gossip. Result: to mesh 3 machines, you must hand-edit each peer file.
  - *Acceptance test:* Start 3 elita nodes on different machines. Each should auto-discover the other two within 5s; `el who` on any machine lists all 3 puppet names.
  
- **P0: Silent partition.** No health check; if a node goes down, others don't know. Connections hang indefinitely.
  - *Acceptance test:* Kill machine B's node. Within 10s, machine A detects it and stops returning stale puppet pids.
  
- **P1: Cookie in code.** Hardcoded `:elita` atom. Should be `ELITA_COOKIE` env var with runtime validation.
  - *Acceptance test:* Export ELITA_COOKIE=foo; two nodes with different cookies cannot connect (expected); same cookie auto-mesh.

- **P1: Manual node naming.** Scheme `claude_<name>@<host>` works, but no guarantee uniqueness if two sessions run the same name on same machine. No session ID or process instance tracking.
  - *Acceptance test:* Start two `el claude malko` on same machine. Both register. Both are discoverable by name + node (not just name).

---

## 2. Registry & Directory (Name Resolution)
**Grade: D (two disconnected systems: directory + registry; puppets invisible to addressing)**

### What We Have

**Registry Layer (Puppets & Agents):**
- `ElitaRegistry`: local Registry (one per node), keys `:unique`, stores `{pid, %{kind: :puppet|:headless|:native, ...}}`
- `El.Puppet`: registers locally + globally (via `:global.register_name/{name, :puppet}`)
- `Agent.Session`: registers locally only (headless agents)
- `Elita`: registers locally only (native agents/runtime)
- Dual lookup in `El.Distribution.target/1`: tries `:global` first, falls back to `ElitaRegistry`
- `Agent.Harness`: looks up only in local `ElitaRegistry` (no cross-node fallback)

**Directory/Addressing Layer (Agents, Scripts, Nodes):**
- `Address.World`: builds a "world" of addressable things:
  - Agents from `AGENT_REGISTRATIONS` env var (folder + scripts)
  - `.exs` scripts found in agent folders
  - Remote nodes (via `Node.list()` — only connected nodes)
- `Resolver`: matches addresses to world entries; supports glob patterns and fanout
- `Address.Route`: uses RPC to route to remote nodes; integrates with resolver
- Supports addressing by name, path/glob, or `name@path` combinations

### The Critical Gap
**Puppets exist in registry layer but are NOT in the directory layer.** 
- `tell agent_name` routes via Address.Route → finds in World (agent/node) → dispatches
- But `tell puppet_name` also routes via Address (if no "@") → NOT in World → Agent.Harness fallback
- Cross-node puppet lookup: Address.Route calls remote node's Address.Route via RPC → remote node searches its World (doesn't find puppet) → remote Agent.Harness searches local registry → found locally but NO registry entry on calling machine
- Result: **puppets cannot be discovered from another machine via the addressing system; queries hang or fail**

### What OTP Gives Free (We Ignore)
- `:global` (process registry, mnesia-backed) survives node restarts but is slow and doesn't scale past ~1000 processes
- `:pg` (process groups, OTP 23+) is fast, distributed by default, can group processes arbitrarily
- Horde library (CRDT-based) handles partition tolerance and eventual consistency
- `{:via, Registry, {name, key}}` can route to any lookup module; we only use local Registry

### Missing
- **P0: :global is per-EPMD, not per-cluster.** Two separate EPMD instances can't see each other's :global registry. Our fallback to `ElitaRegistry` only works on the LOCAL node—`target/1` on machine A cannot find a puppet on machine B unless machine A has already connected via Node.connect.
  - *Acceptance test:* Start Elita on machine A, start puppet on machine B. From machine A's REPL, `el puppet_name` routes to machine B's puppet correctly even if no prior Node.connect.

- **P0: Agent.Harness is local-only.** When a puppet's machine dies, `Agent.Harness` on other machines doesn't know. Queries hang or return stale pids.
  - *Acceptance test:* Machine B hosts puppet "claude_b". Machine A routes to it. Kill machine B. Machine A's Harness detects the death within 10s.

- **P1: No registry survivorship policy.** If a node restarts, its puppets' registry entries vanish. No auto re-register, no orphan cleanup.
  - *Acceptance test:* Start puppet. Query from remote machine. Restart puppet's node. Within 30s, remote machine knows puppet is gone.

- **P1: Puppet metadata incomplete.** Registry stores `kind: :puppet` but not node name, session ID, or TTL. Can't distinguish stale entries.
  - *Acceptance test:* Store `{node: 'claude_a@192.168.1.5', version: 1, ttl: 30}` in puppet metadata. Age out entries older than 30s.

---

## 3. Supervision & Crash Resilience
**Grade: C- (violations of let-it-crash, manual cleanup)**

### What We Have
- `Elita.Application`: one-for-one supervision; starts `ElitaRegistry`, `Agent.Manager`, el CLI
- `Agent.Manager`: starts `Agent.Session` for each configured agent; logs failures but doesn't supervise restart
- `Agent.Session`: GenServer, no child processes, stateless (safe to restart)
- `El.Puppet`: GenServer, links to one external PTY pid, NO restart policy
- `El.Pty`: GenServer, spawns a separate probe process (NOT supervised), spawns a linked stdin handler
- PTY probe: spawns with `spawn/1`, NOT linked to parent, checks port every 500ms

### What OTP Gives Free (We Ignore)
- Supervision trees with `Supervisor` module handle cascading restarts and backoff
- `:permanent` / `:temporary` / `:transient` child specs let us express crash policies
- Dynamic supervisors can add/remove children at runtime without code changes
- Links + traps handle process death notification automatically
- `monitor/2` + `:DOWN` messages let us track external processes (like PTY pids) safely

### Missing
- **P0: PTY death is invisible.** El.Puppet holds a PTY pid but doesn't link to it. If PTY dies (e.g., claude crashes), puppet stays alive with stale pid. Queries timeout or hang.
  - *Acceptance test:* Start puppet. Send query. Kill PTY process. Next query fails immediately (not after 5s timeout); registry auto-removes puppet.
  
- **P0: Probe is unsupervised spawn.** `El.Pty.Init.probe/2` spawns a bare `spawn/1` process with no link or monitor. If probe crashes, PTY death is never detected. PTY can hang for 500ms before next check.
  - *Acceptance test:* Kill probe process. PTY death detected within 500ms (current) → 100ms (with supervised monitor).
  
- **P0: Wrap/STTY cleanup race.** El.Commands.Claude calls `stty sane` at the very END (after/finally block). If puppet process crashes mid-session, terminal state is corrupted. If wrap dies, stty is never run.
  - *Acceptance test:* Start puppet, corrupt terminal (e.g., `stty -echo`), kill puppet. Terminal auto-recovers within 1s (via OS cleanup or supervised handler).

- **P1: No registry cleanup on puppet death.** When El.Puppet dies, `:global.register_name` entry persists; `ElitaRegistry` entry vanishes (Registry is local-only). Clients query :global, get stale pid, crash.
  - *Acceptance test:* Register puppet, query it, kill puppet process. Query within 1s detects pid is dead and unregisters automatically.

- **P1: Agent.Manager logs failures but doesn't retry.** If an agent boots with bad config, it logs an error and moves on. Session is silently missing.
  - *Acceptance test:* Boot agent with bad config. Within 1s, it's marked UNAVAILABLE in health check; retry happens within 30s.

---

## 4. Observability & Silent Failure
**Grade: F (zero structured logging, no health checks, crashes are invisible)**

### What We Have
- El.Trace: custom trace module (unclear implementation)
- El.Pty.Init: uses `El.Reader` and `El.Trace` (no standard Logger)
- El.Commands.Claude: catches errors with `rescue _` but logs nothing
- El.Distribution: logs to stderr on boot failure; silent on connection errors
- Agent.Manager: uses Logger.info/error for startup, nothing else
- No crash dumps, no session logs, no SASL reports
- No health check CLI command
- No metrics (uptime, queries/sec, failure rate)

### What OTP Gives Free (We Ignore)
- `Logger` module with structured logging (json, filters, levels)
- `Logger.Backends` can route logs to file, syslog, or cloud
- SASL supervisor reports (config via `sasl` app startup)
- `erl_crash_dump` auto-generated on OTP crash (contains full state)
- `:sys.trace/2` for runtime debugging of any GenServer
- Application group leaders auto-log startup/shutdown events

### Missing
- **P0: PTY crashes leave zero trace.** When `El.Pty` or its probe dies, there's no log entry. Puppet queries just timeout. Impossible to debug.
  - *Acceptance test:* Start puppet. Force PTY to crash. `el doctor` logs: `puppet@node: PTY crashed at 12:34:56 UTC, reason: SIGTERM, output: [last 100 lines]`.

- **P0: No per-session log file.** Multi-machine queries have no visibility. If puppet_a→puppet_b→agent_c fails, there's no audit trail of which hop broke.
  - *Acceptance test:* Each session boots with log file at `~/.elita/sessions/<name>_<timestamp>.log`. Queries log: `query id=uuid, from=machine_a, to=puppet_b, latency=123ms, result=ok|error`.

- **P0: No `el doctor` command.** Users can't verify platform health. No way to check: is my node connected? Can I reach puppet X? Is my registration stale?
  - *Acceptance test:* `el doctor` prints:
    ```
    Node: claude_session@192.168.1.5 [LIVE]
    Puppets: 3 registered, 2 reachable
      - malko@192.168.1.6 [OK, 5 queries/min]
      - unused@this-node [STALE, last seen 2m ago]
    Network: 2 peers, 1 unreachable (machine_c, down 1m)
    ```

- **P1: No crash dumps on release.** When `el claude` dies, no crash dump is generated. SASL not configured.
  - *Acceptance test:* `ELITA_CRASH_DUMP=~/.elita/crashes el claude malko`. On crash, dump file written; readable with erl_crash_dump viewer.

- **P1: No structured error context.** Rescue blocks swallow errors. No way to know WHY a puppet registration failed.
  - *Acceptance test:* Puppet registration logs: `{timestamp, puppet_name, node, status: 'registered'|'deregistered', reason: 'normal'|'node_down'|'pty_died'}`.

---

## 5. Lifecycle: Boot, Reconnect, Shutdown
**Grade: D (ad-hoc, no orchestration, orphans not reaped)**

### What We Have
- `El.Distribution.start/2`: boots node with retry loop (5 attempts, 200ms delay)
- `El.Distribution.daemon/0`: boots elita daemon, loads peers, connects once (no retries)
- `El.Commands.Claude`: boots PTY via `El.Pty.run`, registers puppet
- Puppet finds existing session via `:global.whereis_name` or spawns new one
- `/exit` in REPL stops the session manually
- No graceful shutdown signal, no orphan reaping

### What OTP Gives Free (We Ignore)
- Application startup order via `.app` file dependencies
- `Application.ensure_all_started/1` waits for all transitive deps
- `:heart` module can restart the Erlang VM if monitoring process dies
- `Supervisor.stop/1` with `:infinity` timeout for graceful shutdown
- Net kernel can track node up/down events via `:net_kernel.monitor_nodes/1`
- `init:stop/0` can be called remotely via `:rpc`

### Missing
- **P0: Daemon doesn't reconnect.** `daemon/0` loads peers once at boot, tries to connect once, then sleeps forever. If a peer boots after the daemon, it's never discovered.
  - *Acceptance test:* Start daemon. Sleep 5s. Start new peer. Daemon auto-discovers and connects within 30s (gossip + health check).

- **P0: No graceful shutdown.** Killing `el claude` mid-session leaves PTY running, doesn't deregister puppet, doesn't restore terminal. `/exit` must be called manually.
  - *Acceptance test:* `pkill -TERM claude_session`. Within 2s: puppet deregistered, PTY killed cleanly, terminal restored.

- **P0: Orphan reaping missing.** If machine B crashes, machine A still has puppet_b in its registry. Queries to puppet_b hang or return stale pids.
  - *Acceptance test:* Machine B crashes. Within 30s, machine A's registry marks puppet_b stale; retry queries fail-fast instead of hanging.

- **P1: Boot order not enforced.** If Elita starts before distribution is ready, Agent.Manager can't register agents. No error, just silent skip.
  - *Acceptance test:* Distribution auto-waits in Elita.Application.start; if it takes >5s, timeout and log a warning.

- **P1: No shutdown signal broadcast.** If user runs `el /exit`, only the local session stops. Remote puppets are orphaned.
  - *Acceptance test:* Local `/exit` sends `:shutdown` signal to all known puppets; they deregister and stop cleanly.

---

## 6. PTY Plumbing & Terminal State
**Grade: D (hardcoded assumptions, no error recovery, contention)**

### What We Have
- `El.Pty.Init`: opens `/dev/tty` directly, fails if not in a real terminal
- Uses Unix `script` command to create PTY with `stty` for size + raw mode
- Resize uses `stty rows <N> cols <M> < /dev/tty` shell command
- Cleanup: `stty sane` called only in `finally` block of `El.Commands.Claude`
- Single tap/untap mechanism per call (watch/unwatch)
- No /dev/tty contention handling (if two processes try to own it, race condition)

### What OTP Gives Free (We Ignore)
- `Port` module can handle multiple simultaneous pseudo-terminal connections
- `:prim_tty` (OTP 25+) gives native TTY control without Unix dependencies
- Process monitors can track TTY lifecycle separately from commands
- Ports can be opened in `:noshell` mode for non-interactive use

### Missing
- **P0: /dev/tty contention.** Two puppet sessions on the same machine both try to open `/dev/tty`. Only one succeeds; the other fails silently or hangs.
  - *Acceptance test:* Start two local puppets (claude_a, claude_b). Both open /dev/tty without race/hang.

- **P0: Hard exit loses terminal.** If `el claude` is killed (e.g., SIGKILL), stty sane is never called. Terminal stays in raw mode, unusable.
  - *Acceptance test:* Kill -9 el claude. Terminal still accepts input (signal handler or OS cleanup).

- **P1: Resize can fail silently.** `stty rows <N> < /dev/tty` fails if called on remote puppet (no /dev/tty on remote machine). Error is caught and swallowed.
  - *Acceptance test:* Remote puppet resize logs failure; client retries or uses default size.

- **P1: Tap/untap is per-query.** Each puppet.ask call must watch, query, unwatch. If unwatch fails, taps leak. Multiple concurrent queries interfere.
  - *Acceptance test:* Run 10 concurrent queries to same puppet. All complete without tap leaks.

---

## Summary: State-of-Platform Grading

| Layer | Grade | Why | Blocks Cross-Machine |
|-------|-------|-----|----------------------|
| Distribution Mesh | D+ | Hardcoded localhost, manual peers, no health check | YES—can't reach other machines |
| Registry & Directory | D | Two separate systems; puppets not in World; dual-layer lookup inconsistent | YES—puppet queries can't route cross-node |
| Supervision | C- | PTY links missing, probe unsupervised, cleanup races | YES—puppet death is invisible |
| Observability | F | Zero structured logging, no session logs, no health CLI | YES—failures are silent |
| Lifecycle | D | No reconnect, no graceful shutdown, no orphan reaping | YES—partial meshes leak state |
| PTY Plumbing | D | /dev/tty hardcoded, resize fails remote, cleanup races | YES—terminal state corrupted |

**Bottom line:** Malko cannot reliably execute the headline job (session-to-session puppeteering across machines). Every critical layer has a P0 blocker.

**Most Surprising Finding:** A sophisticated Address/World/Resolver directory system exists for routing to agents and nodes, but puppets are completely invisible to it—living in a separate dual-layer registry. This causes puppet discovery to fail at cross-machine boundaries.

---

## Missing Pieces: Prioritized List

### P0 (Blocks Cross-Machine Puppeteering)

1. **Puppets integrated into directory system** — Puppet discovery via Address/World instead of dual registry lookup
   - *Test:* `el puppet_name` routes via Address.Route; finds puppet on machine B without manual Node.connect; queries succeed cross-machine.

2. **Distributed node discovery** — Auto-discover peers on LAN; gossip-based + health checks
   - *Test:* Start 3 nodes on LAN. All auto-discover within 5s. `el who` lists all 3 puppet names globally.

3. **Cross-node registry backed by :pg** — Replace `:global` + local ElitaRegistry with `:pg` (OTP 23+); survives node restarts
   - *Test:* Puppet on machine B registers. Machine A queries it immediately. Restart machine B; puppet re-registers; machine A detects new version.

4. **PTY death detection** — Link puppet to PTY; detect crash within 1s; auto-deregister
   - *Test:* Kill PTY. Puppet removed from all registries; next query fails fast.

5. **Health-check daemon** — Nodes periodically verify remote puppets are alive; clean up stale entries
   - *Test:* Machine B crashes. Machine A detects it within 30s; marks puppet stale.

6. **Per-session logging** — Structured logs for boot, crash, queries; saved to file per session
   - *Test:* `cat ~/.elita/sessions/malko_2025-01-15.log` shows all events with timestamps and latencies.

7. **el who / el doctor** — Visibility into mesh state: node status, puppet reachability, network peers, orphan count
   - *Test:* `el who` lists all puppets on all connected nodes. `el doctor` shows node health, connection status, stale puppet count.

### P1 (Improves Reliability / Debuggability)

7. **Cookie from env** — ELITA_COOKIE env var; runtime validation
   - *Test:* Different ELITA_COOKIE values prevent connection.

8. **Crash dumps** — SASL config, auto-save erl_crash_dump on exit
   - *Test:* Kill -9; crash dump written to ~/.elita/crashes/

9. **Session ID tracking** — UUID per puppet instance; survives node restart
   - *Test:* Restart node; same puppet name has new UUID; old queries timeout.

10. **Graceful shutdown signal** — SIGTERM handler; deregister, clean PTY, restore terminal
    - *Test:* Kill -TERM el claude; exits clean within 2s.

11. **Orphan reaper** — Periodic task removes registry entries for dead nodes/pids
    - *Test:* Registry cleanup runs every 60s; marks stale entries for removal after 2 checks.

### P2 (Nice-to-Have / Future)

12. **Tap leak prevention** — Concurrent query support; no manual watch/untap
    - *Test:* 10 concurrent puppet.ask calls; no tap leaks.

13. **Remote resize support** — Client sends size to puppet; puppet configures local PTY
    - *Test:* Resize remote puppet; output reflows to new size.

14. **Partition tolerance** — Nodes learn about partition; mark entries SUSPECT; wait for rejoin
    - *Test:* Network split. Nodes detect partition within 10s; queries fail-fast.

15. **Tailscale/plaintext internet mode** — TLS or plaintext distribution over WireGuard
    - *Test:* Boot nodes on different Internet subnets; mesh auto-forms.

---

## Pick List: Immediate Actions to Ship Malko

**Context:** malkovich.feature is red (wrap dies on cross-puppet input); :global blind between wrap nodes; PTY death is silent (burned 6 debugging rounds). Pick the 3–5 highest-impact fixes to unblock shipping, ordered by payoff.

### #1: Per-Session Logging + Logger/SASL Wiring (Small–Medium, 4–6 hrs)
**Why it pays off NOW:** PTY crashes leave zero trace. Debugging is a mystery: "wrap died somehow". With structured logging to `~/.elita/sessions/<name>_<timestamp>.log`, every crash has timestamp, reason, output. Eliminates the "what happened?" loop that burned tonight's 6 debugging rounds. Direct debugging velocity win.

**Acceptance test:** Start malko puppet, force PTY crash (kill -9 or SIGTERM). Check `~/.elita/sessions/malko_*.log`; file contains crash event with timestamp, OS signal/reason, and last 50 lines of PTY output. Debugging cycle: crash happens → log file consulted → root cause known in <1 minute (vs 6 rounds of guessing).

**Implementation notes:**
- Wire OTP Logger with structured output (JSON format)
- Add file sink to `~/.elita/sessions/`
- Configure SASL application for crash dumps
- Log puppet register/deregister events, PTY boot/death, queries with latency

---

### #2: PTY Death Detection + Auto-Deregister (Medium, 6–8 hrs)
**Why it pays off NOW:** When PTY crashes, puppet stays in :global and ElitaRegistry with a stale pid. Wrap tries to talk to dead puppet → hangs or crashes. With this fix, puppet detects PTY death within 100ms, deregisters from both layers. Wrap stops serving stale pids. Queries fail fast (detected immediately) instead of hanging.

**Acceptance test:** Boot puppet. Kill PTY process (not puppet GenServer; the actual PORT). Within 100ms, puppet is removed from :global and ElitaRegistry. Query puppet immediately after: returns "not found" or error (not stale pid).

**Implementation notes:**
- Link El.Puppet to PTY pid (currently no link; just holds pid)
- Add process monitor to PTY in El.Puppet.init
- On :DOWN message, deregister from :global and local Registry
- Log death event with reason and timestamp

---

### #3: Puppets into Address System (Medium, 8–10 hrs)
**Why it pays off NOW:** :global lookup is per-EPMD (blind between wrap nodes). Address/Resolver already works for agents and nodes. Unifying puppets into that system means cross-puppet queries work via Address.route — no :global magic, no dual registry. When wrap asks for puppet_b, it uses the same routing as agents: discovery works, fallback works, errors are logged.

**Acceptance test:** On machine A, run `el puppet_b ask "1+1"` where puppet_b lives on machine B. Query succeeds (returns 2) without prior Node.connect. Routing goes through Address.Route (not dual-layer fallback). Inspect logs: routing decision logged; no :global query attempted.

**Implementation notes:**
- Expand Address.World to query remote registries for puppets (via RPC)
- Add puppet entries to World with kind: :puppet, node, TTL
- Resolver already handles fuzzy matching; no changes needed
- Update Agent.Harness to prioritize Address.Route for remote puppets

---

### #4: `el who` Command (Small, 2–3 hrs)
**Why it pays off NOW:** Quick visibility. When wrap dies and you ask "is puppet_b still there?", `el who` answers immediately instead of guessing. Shows all puppets on all connected nodes, status (alive/stale), last seen. Debugging aid; unblocks "wait, what's the state of the mesh?".

**Acceptance test:** Run `el who`. Output lists all puppets across all nodes; each shows `name@node [ALIVE|STALE] last_seen=<seconds_ago>`. When a puppet is killed, `el who` reflects the change within 5s.

**Implementation notes:**
- Query all connected nodes' local registries via RPC
- Aggregate puppet entries with node name
- Display in human-readable format (table or list)
- Show TTL/staleness info if available

---

**Rationale:** #1 eliminates the debugging mystery (direct cause of tonight's 6-round pain). #2 prevents stale pids (root cause of wrap crashes). #3 unifies registries (makes cross-puppet queries reliable). #4 is quick visibility (debugging aid). Defer hub/mesh join — Kenny is on Node.connect tactical fix; this is follow-up.

---

## Architectural Recommendations (Not Decisions)

1. **For directory integration:** Expand World to include puppets from all connected nodes via RPC; make Resolver puppet-aware; route puppet queries through Address.Route (not dual-layer fallback).

2. **For mesh discovery:** Start with static peer file + health checks; move to mDNS (Erlang `:inet_mdns`) for LAN; later add Tailscale mode.

3. **For registry:** Replace `:global` dual-layer with `:pg` (OTP 23+); add TTL; implement health checker in background task; keep ElitaRegistry as local cache.

4. **For supervision:** Link Puppet to PTY; add DynamicSupervisor for PTY probe; trap_exit for clean shutdown; deregister puppet on death.

5. **For observability:** Use OTP Logger with structured output (JSON); per-session log file in `~/.elita/sessions/`; SASL for crash dumps.

6. **For lifecycle:** Add `:net_kernel.monitor_nodes/1` for partition detection; graceful shutdown via SIGTERM handler; orphan reaper task.
