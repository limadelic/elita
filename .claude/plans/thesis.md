# YC.md — working notes (living doc)

## What elita is

Smalltalk with the model as interpreter and English as syntax. Agent = OTP process (GenServer), markdown = the program, running live on every call — extreme late binding, Alan Kay lineage completed: every object literally has a brain. ~1.3k LOC engine.

## The algebra (why the primitive set is complete)

Everything is a message send: returns a value (ask/call) or fires into the void (tell/cast). Plus creation (spawn), state (set/get ETS per-agent), composition (includes, recursive merge), role-switch (cast within a composed agent), and the escape hatch to determinism (snippet/tools). Same completeness argument as Smalltalk: there is no other kind of thing a message can be.

## The dial (core language move)

Programmer controls per-construct what stays English vs drops to deterministic code. Two directions:
- compile-time: single-backtick snippets eval'd (Code.eval_string) into the system prompt before the model sees it
- call-time: tool markdown carrying elixir blocks eval'd on tool call
The language prescribes nothing about when to turn the dial — mechanism, not policy. Everyone else compiles the English away (prose); elita keeps it alive at runtime.

## Interpreter

Model is incidental, not a stance — haiku hardcoded right now as placeholder; Ollama qwen via LLM=mlm. Can be WHATEVER, trivially. Same markdown already runs on two interpreters. Tape holds behavior stable across swaps.

## Evidence of compounding (the real pitch shape)

The bet: if agent=process + markdown=code is right, agent-infra products collapse into weekend features:
- tape (VCR, deterministic replay, tape-is-the-spec): days
- speck (spec runner made of agents: trag→tplan→texec): four markdown files
- observability: BEAM tracing, not even turned on yet
Minimalism is not aesthetics — it is the evidence the paradigm is right.

## YC landscape (haiku scan 2026-07)

- Deterministic replay/cassettes for agents: ZERO funded companies (whitespace)
- BEAM agent runtimes: ZERO (whitespace, elita alone)
- Crowded: observability (Respan $5M, Sazabi $8M, Raindrop), eval/simulation sandboxes (5+)
- OpenProse S26: $1.25M, 7k installs, $10k/mo pipeline — funded on "reliable agent workflows" (trust), not the paradigm. Bar is reachable.
- Pattern: YC funds the reliability/trust layer, not runtime substrates.

## Open holes (still investigating)

- speck pipeline: NEVER exercised in tape era — agents + tools fully wired, zero cassettes, only driver died with legacy spec_test.exs (Jul 1), last touch May 27. One mix tape session from proof; if green on today's engine, strongest paradigm evidence (pre-tape program runs unchanged — English didn't rot).
- weave = speck's back half: full chain speck→trag→tplan→texec→mend→web (tplan writes todos, texec spawns workers, mend quality-gates and kicks bad results back to pending, web compiles report). ATDD loop with built-in adversarial review, six markdown files. Same never-exercised status as speck.
- distribution: confirmed NOT shipped — Node.start in chat.ex is just naming; ask/tell strictly node-local via Registry, no :global/:rpc anywhere. Unclaimed OTP territory, honest roadmap item.
- who pays in week one: still open — but the demo question (item 3) is closed, see Killer app below.

## Sequence (per mike)

1. Get elita fully. 2. Decide if worth doing. 3. Only then market to YC.

## Killer app (settled 2026-07-02)

The demo for the agentic platform is a coding machine. Stack: el (erlang agent comms) → elita (the platform, the product) → dude (the demo app). Dude rebuilt on elita: skills become agents (already markdown — elita programs held hostage in the wrong runtime), deterministic bits weed into the dude gem (the dial applied to a whole product), agents talk via erlang instead of returning strings to a parent, harness tools are pi-sized work. Coding agents are so crowded it's used as DEMO not product — dude is elita's Basecamp. Framing (per mike): elita the platform is the sell; dude is the demo doing real work on top of it. No recursion mysticism — a platform and one impressive app that proves it holds weight. Kill shot inside any demo: edit a running agent's markdown, behavior changes next message — no restart, no deploy. Dominoes (doble9) demoted to toy demo. Classic demo pattern honored: Rails made CRUD free, node made real-time free, two erlang shells made distribution free — elita makes societies of English minds free and editable while alive.

## Flaws exam (2026-07-02, adversarial pass — verdict: WORTH DOING)

Every attack dissolved into the paradigm's own answer or a roadmap line:
1. Economics (LLM calls as control flow = slow/expensive) — the classic losing objection to every dynamic language ever; the cost complaint is the signature of being early, not wrong. Withdrawn.
2. Semantic reliability (models fail by being confidently wrong, OTP restarts don't help) — category error: reliability against the model is a PROGRAM, not a platform feature. Adversarial reviewers, retries, judges are agents written in English (mend already is one). Model fuckups are a level playing field — nobody has an edge on elita there. OTP is the hardware layer: reliable comms, many agents, reboots, keeps memory/context. Withdrawn.
3. No load (nobody relies on an elita app daily — all spec, no load) — converts to action, already the plan: el dogfooded a bit, dude is the ultimate dogfooding, demoable-because-dogfooded-while-made. Roadmap.
4. History model (append-only, engine-internal, agents can't prune/slice; a coding machine drowns in its own transcript) — known unbuilt knob, many ways to slice (ephemeral/session/cache), first knob dude reaches for. Roadmap.
5. Elixir escape-hatch tax — the machine writes the Elixir (dude dudes itself, ruby a strong competitor as default), BEAM ports make tools polyglot per project; no bet on humans caring about syntax. Dissolved.
6. Security (eval of model-written code) — commodity problem, solved in sandboxes, hire for it in act two. Not a paradigm question. Struck.

Pattern: every attack lands on "that's a program" or "that's a knob" — the mark of a coherent design under fire.

## Local models (the untouched angle)

Already shipped: mlm.ex, Ollama, LLM=mlm. The insight: elita's decomposition makes local models sufficient — fine-grained agents (a paragraph, three tools, one job) fit paragraph-sized minds; a 7B on your own box runs the greeter/clerk/table agents. Marginal cost of an agent → zero, exactly where monolithic single-agent architectures need a frontier brain for everything.

Consequences:
- Kills the economics objection twice over: control flow bills nothing when minds are local.
- Third axis of the dial: English vs code, and per-agent brain size — frontier for the two agents that reason hard, local for the twenty that clerk. Per-agent model selection is the obvious knob when needed.
- Makes "millions of agents" literal: BEAM does millions of processes free, and the mind per process can be free too. No other architecture can say that sentence.
- Free bonus: whole app on-prem, zero tokens leave the building — privacy/enterprise story without asking for it.

## Napo (after Napoleon) — recursive solver, dude's planner

Take ANY problem, spawn an agent at it; if the LLM can't solve it reliably, split into 2-3 simpler problems and recurse, until the whole tree reliably solves the original. Potential killer app; ultimately dude's planner (a coding task is just this with files).

Why it's elita-native where AutoGPT-era recursive agents died:
- Spawning must be free: forty nodes absurd as Python containers, trivial as BEAM processes (mother/baby is the primitive).
- "Reliably solved" needs a definition: judge at every node; tape freezes a subtree once proven — solved branches replay deterministic and free, only the unsolved frontier burns tokens. Self-annealing tree: English at the frontier, tape behind it.
- Closes the loop with local models: napo discovers the right granularity automatically — the tree grows exactly until each leaf fits an available brain; byproduct is paragraph-sized agents that run local for free.
- Strategic: the compounding engine — agents writing the org chart instead of mike writing every agent.

Honest hard part: recombination — splitting is easy; merging children's answers back into the parent's is where trees historically rot. That's napo's real design problem.

## The essence — swarms, not homunculi

Everyone is building artificial humans: one agent emulating a human — big expensive mind you prompt-engineer and trust like an employee. Elita builds artificial swarms: many small cheap agents, each doing one thing; intelligence lives in the interactions, not in any head. No individual in a swarm knows how to build the collective structure.

Every design choice snaps into place under this lens:
- "Let it crash" is swarm resilience: individuals are expected to die; when an agent is a paragraph with an ETS pouch, mortality is a feature. OTP is the only runtime ever built with this in its bones.
- Local models: organisms are supposed to have small brains — 7B is the correct organ size, not a budget compromise.
- Napo is morphogenesis: grows the swarm to fit the niche, splitting until each agent is simple enough to be reliable.
- Fine grain, one-job markdowns, mechanism-not-policy: simple rules per organism, emergence does the rest.
- Failure inverts: a hallucinating homunculus takes the app down; one wrong ant is noise, mend eats it.

Refinement: a swarm = many identical agents running specialized roles (identical instances are the baseline — robustness comes from redundancy + role differentiation, never requiring genetic diversity). The APP is the ecosystem: many swarms of many species (worker-agents, judge-agents, one mend-specialist), each species its own markdown, each swarm sized to load. Kay built OO on the cell; elita builds AO on the microorganism — objects needed a body, agents just need each other.

## Flaws exam II (essence layer — all dissolved)

1. Legibility vs emergence contradiction — false: this is decomposition/composition (functions, Unix pipes), the most legibility-producing move in software history; and interactions aren't lost — they're BEAM messages, tape records them to readable JSON. A homunculus gives one 200k-token stream to grep; an ecosystem gives small readable minds plus small readable conversations. Legibility squared.
2. Monoculture / correlated failure — wrong taxonomy: identical-agent swarms are the robust structure; diversity lives at ecosystem level (species = different markdown = different phenotype); base-model quirks are level-playing-field weather, per-species brains one knob away.
3. Model progress dismantles decomposition — no: granularity is a slider, not a bet. Bigger model → merge leaves, run tape, judge verifies, done — a refactor, testable for free across models. Elita is the only platform where re-granulating is verifiable; monoliths can't split or verify. Model progress moves the equilibrium leaf size; tape says when you may move it.

Pattern: deeper layer, harder to dent — right shape for a paradigm.
