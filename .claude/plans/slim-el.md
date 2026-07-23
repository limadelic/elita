# Extraction Plan: Slim El

## Goal
Reduce el from ~1300 LOC of infrastructure baggage to lean CLI+domain layer (parse, route, delegate).

## Current State
- `puppet/` (~520 LOC): per-session claude control, ask/put, envelope parsing
- `pty/` (~515 LOC): terminal plumbing, boot, buffer, watch, DSR, dispatch
- `wrap/` (~338 LOC): input routing, RPC delivery, reply handling, resize

Dependency: wrap→puppet→pty (clean pyramid)

## Extraction: Create apps/matrix

### Move to apps/matrix
- `lib/matrix/pty/` (all of it) — terminal substrate
- `lib/matrix/wrap/` (all of it) — routing & RPC layer
- Deps: El.Log, Tape.Store (same as now, stays as internal deps)

### Stay in apps/el
- `lib/el/puppet/` — domain concept (controlled session)
- `lib/el/cli.ex` + commands — thin CLI + routing
- Facades: El.Puppet points to puppet/, El.Matrix points to matrix app

### Interfaces (What el imports from matrix)
```
El.Puppet → El.Matrix.Pty (inject, launch, wait, watch, unwatch)
El.Commands.Claude → El.Matrix.Pty (launch, wait)
El.Commands.Tell → El.Matrix.Wrap.Remote (tell)
```

## Baby Steps (gates green after each)
1. Create apps/matrix mix project + supervisor
2. Move pty/* into matrix; update imports in puppet
3. Move wrap/* into matrix; update imports in commands, puppet
4. Add matrix to umbrella config, matrix to el deps
5. Verify all tests green, lint clean

## Circular Dependency Fix (37 El.* refs in matrix)

**Diagnosis**: matrix imports El.Puppet, El.Distribution, El.Commands.Size, El.Log, El.Trace, El.Reader. Cannot add el→matrix dependency (el already depends on matrix). Must invert/move to break cycle.

### Prescription (per module)

| Module | Verdict | Fix |
|--------|---------|-----|
| El.Log | MOVE | Become Matrix.Log; matrix owns logging infra |
| El.Trace | MOVE | Become Matrix.Trace; matrix owns event tracing |
| El.Reader | MOVE | Become Matrix.Reader; matrix owns stdin I/O |
| El.Distribution.wait | INVERT | Pass wait fn in options; wrap/remote receives `{wait: &wait/1}` |
| El.Distribution.target | INVERT | Pass target fn in options; wrap/reply receives `{target: &target/1}` |
| El.Puppet.ask | INVERT | Pass ask fn in options; wrap/rpc, wrap receives `{ask: &ask/2}` |
| El.Puppet.put | INVERT | Pass put fn in options; remote/reply receive `{put: &put/2}` |
| El.Puppet.Collect.collect | DEFER | Pass collect fn as callback arg; leave in el |
| El.Commands.Size | INVERT | Pass size fn in options; wrap/resize receives `{get_size: &size/0}` |

### Implementation Order
1. Move Log, Trace, Reader into matrix lib (mirror structure from el)
2. Update all imports in matrix to reference Matrix.* instead of El.*
3. Identify callback injection points in wrap/* (remote, reply, rpc, resize)
4. Update Commands.Claude to wire callbacks when launching matrix functions
5. Verify gate green after each micro-step

## Open Questions
- Matrix.Log: init at matrix app startup or via callback from el?
- Tape integration: should Matrix.Trace emit to Tape, or pass recorder as callback?

## Naming
Provisional: "matrix" = pty + wrap substrate (emulator + routing).
Could also be: "conduit", "transport", "channel". Pick after seeing code clean.
