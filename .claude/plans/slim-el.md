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

## Open Questions
- Does matrix need its own supervision tree or just lib functions?
- Should El.Log stay in el, or move to shared infra?
- Tape integration: should matrix depend on tape, or stay agnostic?
- CLI: any wrap-level commands that need facades in el?

## Naming
Provisional: "matrix" = pty + wrap substrate (emulator + routing).
Could also be: "conduit", "transport", "channel". Pick after seeing code clean.
