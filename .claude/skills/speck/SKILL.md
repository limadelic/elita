---
name: speck
description: Speck tests agents — spec runner made of agents. Use when running, taping, or extending speck.
---

# Speck

Napo makes agents. Speck tests agents. A spec runner made of four markdown files: speck → trag → tplan → texec.

## The chain

- `speck` — entry. "exec <spec>" → sets spec in mem, casts to trag
- `trag` — RAG. spec tool reads `<spec>_spec.md`, agent tool reads the Sut + other agents, casts to tplan
- `tplan` — plans SMART scenarios {name, behavior, status: pending}, stores via set, casts to texec
- `texec` — gets scenarios, spawns Sut agents, tell/ask per scenario, marks passed/failed, summary with overall Passed or Failed
- weave = speck's back half (→ mend → web): quality gates + report, same never-exercised status

## Specs

- Live in `test/specs/<name>_spec.md` — frontmatter `agents:` names the Sut, body = Sut description + Scenarios
- 5 specs: agent (greet), ask (doctor), mem (todo), spawn (mother/baby), tell (boss/worker)
- spec tool appends `_spec` — `speck("agent")` reads agent_spec.md, NOT greet_spec.md

## Driver

- `speck(name)` in Tester: `spawn(name, :speck)` then `verify(name, "passed", "exec #{name}")`
- The runner agent gets NAMED after the spec and loaded with speck configs (includes pull trag/tplan/texec)
- Old driver `test/spec_test.exs`: 5 one-liner tests, green Feb 5 (31780ad), killed Jul 1 as legacy (97497d8), never taped

## Stakes

- Zero cassettes exist — pre-tape program. Green on today's engine = strongest paradigm evidence: English didn't rot
- Expensive live: 4-agent chain + spawned Suts per scenario — tape once, replay forever (use tape skill)

## Tape risk

- texec spawn names are LLM-chosen, not deterministic — replay matches entries by agent tag, so a re-record can shift names
- Judges/asks inside the chain follow normal tape rules — record on a clean cassette, audit agents in the diff
