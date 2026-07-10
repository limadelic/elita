# Speck Plan

Napo makes agents. Speck tests agents. A spec runner made of four markdown files: speck → trag → tplan → texec. Goal: resurrect it green and taped on today's engine.

## Stakes

- Zero cassettes exist — speck is a pre-tape program (green Feb 5, 31780ad; driver killed Jul 1, 97497d8)
- Green today = strongest paradigm evidence: pre-tape program runs unchanged — English didn't rot
- Expensive live: 4-agent chain + spawned Suts per scenario — tape once, replay forever (tape skill)

## What speck is

- `speck` — entry. "exec <spec>" → sets spec in mem, casts to trag
- `trag` — RAG. spec tool reads `<spec>_spec.md`, agent tool reads the Sut + other agents, casts to tplan
- `tplan` — plans SMART scenarios {name, behavior, status: pending}, stores via set, casts to texec
- `texec` — gets scenarios, spawns Sut agents, tell/ask per scenario, marks passed/failed, summary with overall Passed or Failed
- weave = speck's back half (→ mend → web): quality gates + report, same never-exercised status, NOT in this plan
- Specs in `test/specs/<name>_spec.md` — frontmatter `agents:` = Sut. 5 specs: agent (greet), ask (doctor), mem (todo), spawn (mother/baby), tell (boss/worker)
- spec tool appends `_spec` — `speck("agent")` reads agent_spec.md, NOT greet_spec.md
- Driver helper lives in Tester: `speck(name)` = `spawn(name, :speck)` + `verify(name, "passed", "exec #{name}")`
- Old driver was test/spec_test.exs: 5 one-liners calling speck()

## The plan

One spec per cycle, cheapest chain first: **ask → tell → mem → spawn → agent**. Per cycle:

- Test file per spec in `test/speck/` (one test per spec: `speck :<name>`), setup binds CASSETTE, :live tagged
- Record per tape skill: clean cassette, detached, poll, timeout budgeted
- Audit the green (cassette diff, agent tags, real work), replay off tape, commit test + cassette
- Fix engine/replay frictions as they surface — pilot eats them so the rest ride free

## Known risks

- texec spawn names are LLM-chosen — replay matches by agent tag; if names drift on re-record, replay matching needs a fix (turn-tiebreak learnings from napo apply)
- `verify` = blocking ask on the speck agent — chain is casts (async), speck agent must answer only when texec reports back; if it answers early or blocks, driver may need the tell-and-poll treatment
- attempts/judge loops inside texec could blow timeout budgets — start with 1_200_000 tag
