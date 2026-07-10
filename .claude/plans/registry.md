# registry — elita gets her body

## THE ABSTRACTION (2026-07-06 night, settled with Mike): filesystem

The directory IS a filesystem spanning machines. One tree, one grammar,
nothing new to learn — "it's ls, but more." Plan 9 energy: everyone is
a path.

- Tree: network `/` ⊃ machines ⊃ folders ⊃ agents. Machines are just
  the top-level folders (`ls /` → `work/ mini/`). No special syntax,
  no `//`, no `work:` — a machine is a directory that's a computer.
- `ls` is canon (NOT renamed lx — muscle memory IS the product):
  `ls` = `ls ~`, `ls .` here, `ls ..` up, `ls /work` a machine,
  `ls /` the world. Same path grammar for tell/ask/ls alike.
- `cd` = teleportation. The repl STANDS somewhere; relative names,
  spawn, `el rec` happen where you stand. `cd /mini` and you're there.
  Prompt shows feet: `mini:crew >`.
- HOME twist: `~` = where you ran `el` (birth folder), not machine
  root. Two terminals from different folders = two people in their
  own projects, same elita, same tree.
- Agent address = email: `name@path` (`kenny@/mini/lab`). Bare name
  works while unique; ambiguity is paid only by the agents causing it.
  Path after @ can be absolute, relative, glob (`tell @*/crew`).
  One resolver: pattern → matches. 0 = typo error, many on ask =
  ambiguous error, many on tell = fan-out. Address grammar does
  discovery + disambiguation + broadcast in one shape.
- Fan-out: any tree node is addressable — `tell crew/`, `tell /mini`,
  `tell /` — message cascades down the subtree. Folders are teams.
- Registration is a SIDE EFFECT OF EXISTING, never a verb: repl boot
  registers, puppet boot registers, `el <cmd>` in a folder registers
  that folder (implicit name = folder basename), first address by
  path registers it. Registry = live truth (Registry, monitor
  liveness) + disk trail (where life has happened, survives reboot).
- Network: type `el` on two machines sharing the cookie → they find
  each other, zero ceremony (auto-discovery, redial known peers on
  boot). Cookie is the only door. DISTRIBUTION IS FIRST-CUT SCOPE,
  not a later gap — Mike runs 2 machines with projects that must
  talk day one.
- `el` bare = elita alive on this machine (boot if absent), repl is
  a visit not her lifespan. A project = inactive agent whose spec is
  a folder path, asleep until knocked.
- Scout correction: og el ls is node-local (el.ex:93-96) — union ls
  across nodes is NEW work, only daemon/rpc plumbing is proven.

## Round 2 (same night): agents are files, memory over heartbeat

THE PRODUCT IS A KNOWN DSL over 1986 primitives: shell grammar
(paths, ls, cd, ~, @, globs) compiling to Registry/:pg/:erpc/
monitors/DynamicSupervisor. Resolver = deterministic Elixir, pure
address-string → matches, unit-tested to death, $0. Design tell all
night: hard questions kept answering themselves from the filesystem
or OTP — the sign the abstractions are true.

- AGENT = A FILE. doctor.md anywhere on disk IS doctor, asleep. No
  agents/ dir, no format requirement — ANY file wakes (`ask README.md
  what do you do` — content becomes self). md+frontmatter is just a
  file that wakes up well-dressed. Name = filename. Tree = the REAL
  filesystem, nothing parallel to sync.
- Asleep discovery = filesystem semantics, NO search tier: awake =
  Registry (visible everywhere), asleep = visible where it lies,
  addressed by path like any file since 1970. Nobody expects ls to
  see folders they're not looking at. (Trail-scan/locate idea: born
  and killed same night.)
- Globs do mass wake: `tell crew/* standup`, `ask */doctor.md ...`,
  `tell /nyc/**/doctor.md` — fan-out is not a feature, it's a glob.
  Guard: show match list before send when > a few.
- Wake pipeline: glob → file → DynamicSupervisor starts GenServer
  (self = file content) → registers → ask lands → answer. Five
  steps, all named primitives.
- PROXY PRINCIPLE: nothing enters the directory except as a process;
  every non-BEAM thing gets a proxy GenServer (puppet = pty wrapper
  IS the proxy; zombie/headless = proxy holding session-id, asks
  queue through it — kills spawn-per-ask amnesia). Port closes →
  monitor → unregisters.
- ORPHANS: elita restarts, wrapped session survives → real thing
  alive, proxy dead. On boot elita ADOPTS: trail remembers what ran,
  check who survived, re-proxy the living. Crash-reattach = boot
  ritual, not disaster.
- MEMORY over HEARTBEAT (Mike's cut): agent = self (file) + memory
  (session/context on disk) + optionally-right-now a heartbeat
  (process). The promise is continuity — he remembers tomorrow —
  process-or-not is engine economics (keep warm vs cold-resume).
  ls "active" means "conversation you can rejoin", not "has a pid".
- Lifecycle: GenServer per session, state = context, write-through
  every turn (crash = unplanned sleep, lossless). DEFAULT: warm with
  idle ttl. Knob = one frontmatter word — lifecycle: ephemeral |
  warm (ttl: 30m) | resident — which is literally OTP :temporary /
  :transient / :permanent. The file states its nature.
- Context tweaks: don't design, leave the seam — context is state,
  get/set already in verb family, become already a context op (swap
  self, keep memory). Compaction/trim/share = later English policy.
- Supervision tree ≠ directory tree: supervisor = who keeps you
  alive (blast radius, invisible), Registry = your name, :pg = your
  paths. Meaning and fault-tolerance don't share a shape.

## Round 3 (same night): cross-node = homebound processes

- Security/trust/hidden folders: OUT OF SCOPE now. Cookie = the door.
- HOMEBOUND RULE: every process starts on the machine that owns the
  file (BEAM shares messages, not filesystems). Resolver splits
  address → machine + local path, :erpc the wake to that elita; she
  globs her own disk, starts the agent under her own supervisor,
  registers in her own Registry. Only the pid crosses back.
- Cross-node ask/tell: remote pid is just a pid — message hops the
  wire to the proxy, proxy talks to claude locally, answer rides
  back. THE MESSAGE TRAVELS; THE SUBPROCESS NEVER DOES.
- Each machine cleans her own house: monitors own proxies, adopts
  own orphans on boot. Network shares exactly three things: names,
  messages, pids. Files/processes/sessions/supervision: homebound.
- Only new mechanism for all of this: the relay — "resolves to a
  peer, forward" — one :erpc call inside the resolver.
- Remote start confirmed trivial: :erpc.call(node, DynamicSupervisor,
  :start_child, [spec]) — runs on peer's CPU/disk, pid comes back,
  file reads are local reads.

## Zombies: tool prefix selects the mouth (Mike was right, 07-07)

`claude ask rec@work/dev` / `codex ask rec@work/dev` / bare `ask rec`.
One name (the folder), a session PER TOOL behind it, coexisting with
own memories. Prefix = optional selector picking which mouth; born on
first knock in any folder, no .claude/ required (claude -p creates
it). Bare verb = whoever's warm, else default harness (policy, one
line, likely claude). Polymorphism intact: bare verbs always work on
everything; prefix selects, never required. Harness is per-agent/
session, NEVER per-folder — claude and codex share rooms freely.
Explicit harness demanded but not installed = honest error. Dude
(native) = the floor, answers where no tool exists.

## Round 4 (07-07): agents are files, SESSIONS are conversations

The floor under everything (Mike found it): there's only ever doc;
every name we invented was naming a CONVERSATION with doc.

- AGENT = the file. Permanent, one per file, never squatted, never
  copied. Wakes AS WRITTEN every time (shell semantics: running a
  program doesn't resume the last guy's run — no first-caller
  squatting the shared brain). Files can self-name via frontmatter
  (name: doc); filename is the default name.
- SESSION = a conversation with an agent. Has the memory, warmth,
  lifecycle — and optionally a NAME.
- bare `ask doc` = YOUR private session, automatic, DM semantics.
- `spawn ward doctor` = a NAMED session: registered, in ls, everyone
  saying ward lands in the SAME conversation (channel semantics).
  Shared only ever happens through a deliberate name.
- NOTHING STATIC: name's real job = "I can come back to this one."
  Sharing is a consequence of handing the name out, not of naming.
  Also names for multiple private sessions (spawn p1/p2 player).
  No name = disposable + mine; name = returnable; spoken = shared.
- Instances/clones/singletons/static — all dissolved into sessions.
  Claude's own .claude sessions are literally already this; project
  folder continuity = the folder's default session.
- Registry ACTIVE entries = sessions (named + warm private);
  prototype/OO vocabulary dropped.

## Open threads (parked tired, 07-07)

- Private-session identity: what makes it "mine" — repl session id?
  caller pid? survives repl restart? (DM resume semantics)
- ls columns final shape: agents (files) vs sessions (conversations)
  — two kinds of rows now, render honestly.
- Session GC: unnamed cold sessions pile up — ttl/eviction policy.
- become interacts with sessions how? (swap self mid-conversation —
  probably just works, verify.)
- ask done-detection (tell-based ask) still the standing wart.
- Puppet (terminal takeover) unchanged by session model — confirm.

## agent.md = index.html (Mike's discovery, same night)

Ask a FOLDER and it answers through its agent.md — the folder's
face, its receptionist. No agent.md → the default seat (dude) picks
up standing in that folder with its context. Every folder is
askable, always. This retro-explains "el in a folder registers the
folder": the folder was the agent all along; agent.md is its custom
personality. Convention over configuration, the web's oldest trick.

Session seed (2026-07-06, post-poc retro with Mike). Supersedes the
claude_* node naming from poc — that was claude-shaped plumbing;
claude is nothing, a command string a session happens to run.

## The picture (Mike, verbatim spirit)

- brew install elita — that brings el. One product: elita, resident
  on the machine. el is her mouth.
- `el` bare = THE REPL. You're in, talking to her. Not a dispatcher.
- In the repl: `claude` = like running claude in a shell (puppet wrap
  takes the terminal, exit falls back to repl, session is hers).
- In the repl: `ls` = the directory.
- In the repl: `1 + 1` = 2 — plain talk goes to the DEFAULT AGENT,
  a markdown elita agent (el or dude — seat undecided, swappable live).
- Default agent has ALL elita tools: ask/tell/spawn/ls — routing is
  the agent using tools, not repl syntax. CLI = thin pipe.
- Directory: ACTIVE (live processes) + INACTIVE (markdown on disk,
  wakeable). Typo = error because it matches neither.
- Agent kinds: elita agents; claude via HEADLESS (-p port) and PUPPET
  (PTY wrap); eventually codex/pi/any headless-or-puppetable tool;
  A2A maybe later. Those harnesses generalize plenty. No kind
  prefixes in names ever — kind is a property, not a namespace.

## Erlang-native registry (invent nothing, it's 1986's problem)

- Alive = ElitaRegistry (exists: apps/elita, unique keys, monitor-based
  liveness — death unregisters for free).
- Cross-machine = connected elita nodes; view = rpc Registry.select
  per node, union (og el proven). :pg/:global on the shelf if it grows.
- Inactive = the filesystem; ls = Registry ∪ disk.
- Names scoped per elita; @host qualifies only when ambiguous.

## Honest gaps (engine work, Elixir)

1. RESIDENCY: elita as mix release + daemon; today every el command is
   a one-shot escript whose registry dies with it. This is THE gap.
2. DISTRIBUTION: never shipped in elita (ask/tell is node-local).
3. Wrap as supervised child of elita, terminal = attached pipe →
   detach/attach falls out of the architecture.
4. Tools exposing registry verbs to agents (sys/tell exists; ls/spawn/
   wake need the same shape).

## Donor organs (og el, proven since April, scouted 2026-07-06)

- rel/formula.rb.template + rel/overlays/bin/el_wrapper — brew formula,
  wrapper does `bin/el rpc "El.CLI.dispatch(...)"` into live node.
- lib/el/cli/daemon/connection.ex — CLI node el-cli-<id>, Node.connect,
  auto-spawn daemon if unreachable (:104). Daemon = same release +
  sleep(:infinity) (cli/start.ex:51).
- lib/el/cli/daemon/env.ex — EL_HOST (host, default 127.0.0.1),
  EL_NODE (full node override — host vs node, NOT redundant),
  dots→longnames (:27), dev/prod cookie split.
- session/registry.ex:13 — ls = Registry.select(El.Registry,
  [{{:"$1", :_, :_}, [], [:"$1"]}]) |> Enum.sort()

## Survives from poc (keep)

pty.ex byte relay + DSR answer + taps/input seams; byte-at-a-time
/dev/tty reader; \n→\r input hook; EL_TRACE; honest one-test e2e
(wrap.sh, fails on <20s/stacktrace/early-exit, prints bill);
ESC[?2004h readiness signal; bin/el EL_ROWS/EL_COLS launcher.

## Dies from poc

claude_<name> ad-hoc nodes; epmd-grep ls; tell's local fallback
roulette (found → deliver, not found → error, one behavior).

## Method canon (Mike, tonight)

Design like Wirfs-Brock (RDD: agent markdown = CRC card that runs —
role, responsibilities, collaborators = ask/tell graph). Implement
like Beck: deterministic Elixir FIRST while responsibilities are
unknown — you can't extract what you haven't discovered. Migrate with
the dial: lifting code into English is extract-till-you-drop across
the paradigm boundary. Referee with tape: replay coverage is the
PRECONDITION for any lift; extraction without it is rewriting and
praying. Engine = mechanism (residency, distribution, registry,
harnesses, tools). English = policy (default seat, dispatch prose,
what ls shows, supervision judgment). The extraction signal: you want
to edit it while she runs.

## become (settled tonight, was "cast")

Role-switch verb: same process, same pouch, same history — new
markdown self next message. Named BECOME, not cast: it's the actor
model's own lost primitive (Hewitt: spawn/send/become; Akka
become/unbecome; Smalltalk become:) and cast collides with OTP's
async send in every BEAM-literate head. Repl default seat = el
becomes dude (swappable, undecided vs el). "behave like a doctor" →
become doctor, NOT spawn — memory survives the identity swap; that's
the magic and the contamination risk. When become vs spawn is POLICY
(dispatch prose), engine just ships the verb. Family complete:
spawn, ask, tell, set, get, become.

## become rename: tape verified safe (scout, tonight)

Tape matches cassettes by agent+last-message content only (record.ex:10,
play.ex:38) — tool names never enter matching. 8 cassettes hold
literal "cast" in recorded tool_use answers but replay unaffected.
RENAME SAFE, no retape. Rename lib/tools/sys/cast.ex + 6 markdown
`tools: cast` declarations (speck/tplan/trag/mend/attempt/napo.md:3).

## Cost law carries over

e2e = ONE test ONE session ONE haiku prompt; develop on unit tests;
haiku before any billed prompt. See CLAUDE.local.md.
