# Bowling — multi-lane agent delegation

Draft of the bowling skill — multi-lane delegation. Promote to .claude/skills/bowling when stable. Captured live during the malkovich sessions (2026-07-10/11).

## The league

- The Dude — supervisor, main lane (`malko` dir + branch): reads summaries, routes briefs, never touches files or logs directly (haikus fetch, specialists do)
- Walter — lane 2 (`malkov`): aggressive fixer lane; strong opinions, gets caught crossing lane lines, audited hard
- Donny — lane 3 (`malkovich`): reference/verification lane; out of his element, finds gold anyway
- Jesus — reserved: the heavy lane we bring out for the real deal (cross-machine, the endgame); when Jesus bowls, everything else holds

## Core shape

- Full clones as lanes, sibling dirs, branch per lane off main branch (`malko` → `malkov`, `malkovich`)
- NO worktrees: shared .git = shared invisible state; clones are dumb and honest (own git, own _build, own runtime)
- Main lane is the ONLY lane that pushes to origin; side lanes hand findings to the main lane, ship as main-lane commits
- Merge not rebase; lanes re-branch fresh from main after each merge

## When to bowl

- Split one wall into different attack strategies (fix / shrink repro / pin reference) — lanes race, first proof wins
- Pipeline: main lane lands the current change while a side lane pre-solves the NEXT wall (e.g. replay-stub fix designed before the cassette exists)
- Shenanigans lane: mechanical, high-churn, zero-design work (credo/lint fights, mass renames, formatting) gets its own lane so it never clogs feature work
- DON'T bowl: single-file edits, anything needing one shared runtime, work faster to do than to brief

## Lane discipline (learned the hard way)

- Distinct agent/node names per lane (romeo/juliet, hamlet/ghost) — shared epmd/:global means same-name lanes corrupt each other's runs
- Enforce names in the brief AND check session-log cwd/names in reports; subagents drift back to the familiar names
- Never run the same feature (same names) live in two lanes at once
- One tree = one writer: exactly one agent mutates a given lane at a time; read-only analysts can run anywhere
- Reap before you diagnose: stale beams/epmd entries from days ago poison live runs; clean-room checks (ps + epmd -names) before any live conclusion

## Racing modes

- Different angles: each lane attacks the same wall differently (fix it / shrink the repro / pin the reference behavior)
- Same fix, N variants: when a fix has multiple plausible shapes, one variant per lane, first green wins, winner merges
- Cheap read-only lanes: predictor agent maps the code path so run logs get read against a theory, not cold

## Supervision loop

- Supervisor never reads files/logs directly — haikus fetch, supervisor judges summaries; keeps context lean over long sessions
- No subagent ends on a promise: report contains the pasted result or it gets immediately re-tasked
- 5-min rule refined: 5 min with no ARTIFACT (no log growth, no run in flight, no message) = kill and re-brief smaller; sanctioned waits (a 300s test timeout) are exempt
- Adversarial audit before believing green: fast green is suspect (timing plausible? cassette on disk? which binary ran?)
- Evidence over narrative: coder-agent root-cause claims are wrong ~half the time; the pasted diff/bytes/logs are the deliverable
- Baby-step TODOs: one visible outcome each; supervisor chains automatically on notifications, only surfaces at done/blocked
- The supervisor delegates EVERYTHING including doc edits like this one — "it's faster in my context" is how context dies; no middle ground

## Brief anatomy (what every lane brief must contain)

- Lane dir + branch + node names, stated explicitly (agents drift to familiar names)
- The task as WHAT not HOW, with one visible outcome
- Hard constraints repeated verbatim (never push from side lanes, never touch protected pids, sterile gate before live runs)
- Required evidence in the report: pasted diffs, pasted command output, pids, shas — never narrative alone
- Detached-run pattern for anything long: nohup + log in scratchpad, report pid immediately, a later task reads the log

## Honesty machinery

- Remove the fake (stub) from live paths entirely + loud guard if one is found; re-add after the real path is proven
- Unfakeable assertions: pick a check only the real thing can pass (1+1=2 beats splash-art matching)
- Record-then-adjust (tape): record live first, rewrite assertion text verbatim from tape; never chase hand-written assertions live
- Fresh-clone compile from HEAD re-verifies that COMMITTED code works — caught a bug the dirty main dir hid under stale bytecode
- A silent rescue can be load-bearing: fixing a swallowed crash can flip a green suite red (the crash was suppressing side effects, e.g. distribution console noise). Green-because-broken is a real state; test after every isolated fix

## War-story index (why each rule exists)

- ANSI wait-pattern: harness matched plain glyphs, real claude interleaves color codes → 24h "hang" (fix: strip ANSI before matching)
- Prompt drop: send() to unregistered bare atom silently vanishes (Erlang) → sender prompt never returned
- whereis(via-tuple) raises → distribution silently dead for a whole day while suite stayed green
- Three lanes on malko/malkovich names at once → nodistribution errors, uninterpretable runs
- Five "live" runs that were secretly stub: TAPE default was replay; env verification (ps of actual spawned command) is mandatory
- Full-suite lane collisions: lanes running the FULL suite collide on shared epmd even when new features use renamed agents, because inherited features carry the original node names (malko/malkovich/door/portal) — full-suite runs are machine-exclusive; preflight `epmd -names`, wait with lsof, never kill
- Foreman venue drift: a foreman worked in the main dir while briefed for a lane and committed to the wrong branch — briefs must demand `pwd` + `git branch --show-current` pasted first, and reports verified against them
- Credo disables are a cheat class: under census pressure agents reach for credo:disable comments and .credo.exs edits — name both as forbidden explicitly in every lint brief, and audit for them

## Endgame (why malkovich exists)

- Today the supervisor is the switchboard: every inter-lane message flows through one context — micromanagement burns it down
- Target: supervisors talk to supervisors over el (`malko> walter status?`) — Walter runs his own kenny, hands back a summary
- Delegation goes recursive; main context holds outcomes, not operations
- Bowling is the manual protocol we automate away once agents converse
