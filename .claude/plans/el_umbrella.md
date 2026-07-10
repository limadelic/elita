# el umbrella — execution plan (2026-07-04)

Target: `el ask greet hello` prints greet's reply. Umbrella: apps/elita + apps/el (fresh).

## Steps (each green, committed, pushed to wip)

1. ✓ Umbrella conversion, apps/elita only — git mv lib/config/test/bin/agents/credo_checks/priv/mix.exs
   down; root mix.exs (apps_path); fix agents/+cassettes path resolution (app-dir relative, not cwd);
   gates from root AND apps/elita; escript still builds.
2. ✓ apps/el skeleton — fresh app, escript el, {:elita, in_umbrella: true}, builds, no behavior
3. ✓ el ask — `el ask greet hello` wired to elita ask; test replays greet cassette ($0)
4. ✓ cartman review, fixes, PR wip→main

PR: https://github.com/limadelic/elita/pull/8 (open/unmerged, awaiting mike's review tomorrow morning)

## Then (post-beach, kent's banked plan)

Registered external agents — headless claudes behind same ask/tell:
- Agent.Registry (name→folder/session), Agent.Session (claude port, ported organ from
  ~/dev/self/el wip: El.Session), Agent.Router (dispatch: markdown registry first, external second),
  Agent.Config + Manager (boot registrations)
- ask.ex/tell.ex route via Router; caller never knows the kind
- cross-machine after: port Daemon.Env/Connection (EL_HOST/EL_NODE, shipped in el wip bd00048)

## Rules for whoever executes

- wip only, never main, never force, never rebase; commits max 10 words
- elita style: single words, import functions, small pattern-matched functions, pipelines, no comments
- don't touch: test/cassettes content, agents/ content, old el repo
- stuck ≠ hack: stop and report
