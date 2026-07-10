# el as agent — design (2026-07-04)

Replaces Agent.Router only. Thesis application: el's dispatch policy IS a markdown agent, not hardcoded routing.

## The agent: el

Entry point. Pure judgment: given a chat request, decide whose name meant and what kind of mind that is.

Three cases:
1. Cluster markdown agent: spawn/ask via elita's existing spawn + ask/tell
2. External registered claude session (local): wake its session (Agent.Session pinned to a folder), ask/tell
3. External registered claude session (remote): wake across EL_HOST/EL_NODE (distributed Erlang, not ssh), ask/tell

## El's tools (all existing mechanism code)

No judgment in tools, so remain deterministic, NOT separate agents:
- **registry.lookup(name)** → Agent.Registry, ETS-backed: name → {kind, folder/node}
- **registry.register(name, kind, folder/node)** / **registry.remove(name)** → same
- **session.ask(session, msg)** / **session.tell(session, msg)** → Agent.Session, wraps `claude -p` port pinned to folder
- **bridge.reach(node, name, action)** → cross-machine send via EL_HOST/EL_NODE (ported organ from el wip: Daemon.Env/Connection)

El chains these: lookup → if cluster, spawn; if local, wake session; if remote, bridge.reach. Caller always uses ask/tell, never knows the kind.

## Not built now

- **Capacity/quota agent** (deferred): would route between two capable machines by load/time-of-day. Only justified by real ambiguity. Brain/legs roles (home runs cluster, work runs thin client) are fixed, no need yet.
- **Tape extension** (banked idea): cache same-question-to-same-registered-claude conversations across both dispatch paths (cluster vs external), same way raw LLM calls cache. One-liner in design, not a spec.

## Scope locked

This replaces Agent.Router only. Agent.Registry, Agent.Session, Agent.Config, Agent.Manager stay exactly as is (become el's tools).

## Timing

Explicitly NOT started. Mike undecided when to build. This design captures scope/rationale only, no execution signal yet.

## See also

el.md § "Next direction: el as agent" (pointer to this doc).

## Build plan

**Phase 1: Grounding (el as agent dispatch)**

1. Create Tools.Sys.Registry.Lookup with lookup(name) tool — registry query with no side effects
2. Create Tools.Sys.Session.Ask with ask(pid_or_name, msg) tool — asks pinned session, no routing
3. Create el.md agent — prose dispatches: lookup registry, if found ask session else spawn+ask
4. Boot el in Application.start — Elita.start_link(:el, [:el]) ensures always available
5. Update Tools.Sys.Ask/Tell to call el — Elita.call(:el, "ask/tell <name> <msg>") instead of Router.route
6. Verify greet test passes — el spawns greet, asks it, returns response (tape replay $0)
7. Verify dude test passes — el finds dude in registry, asks its session (tape replay $0)

**Phase 2: Remote agents (deferred)**

- Create Tools.Sys.Bridge.Reach — distributed Erlang send to EL_HOST/EL_NODE
- Update el.md to dispatch remote registrations via bridge
- Test cross-machine ask/tell
