# Napo

Napo takes a problem and makes an elita app that solves it.

State the problem in English. Napo writes the agents — species, roles, tools, wiring — as markdown, spawns them, and where an agent can't handle its piece reliably, splits that piece into simpler agents, recursively, until the app works. The output is not an answer: it is an app you keep — readable, tape-testable, running on elita, extractable by copying the folder out.

## Smalltalk nature

Napo is an elita app running on elita that builds other apps in the same live runtime — the Smalltalk image reborn: the environment is not where programs run, it is where programs live and are grown. Builder and built are neighbors in one registry; no compile step, no deploy boundary. Nobody in the agent world has anything like it.

## Why napo over dude

- dude (coding machine) races frontier models — it competes with Claude Code and gets obsoleted as models improve while you type
- napo's scope grows WITH model improvement: better models = coarser leaves, shallower trees (merge leaves, run tape, judge verifies — re-granulating is a refactor, testable free across models)
- dude builds code; napo builds agents. Less area, more powerful scope. Nobody is crowded there at all.
- ultimately napo can still become dude's planner, but napo stands alone first

## Design seed

- napo is ordinary elita agents: spawn exists, writing markdown is a file tool. No new runtime needed.
- "reliably solved" = judge at each node; tape freezes proven subtrees (solved branches replay free/deterministic; only the unsolved frontier burns tokens — self-annealing)
- leaves sized to available brains: fine-grained agents fit local models, cost → 0 (mlm/Ollama shipped)
- THE hard problem: recombination — splitting is easy; merging children's answers back into the parent is where trees rot. Design effort goes here.
- swarm dynamics apply: napo grows ecosystems (many species, swarms sized to load), morphogenesis not planning

## The image (elita as installed runtime)

OPEN QUESTION — distribution shape undecided. Leading candidate below (runtime + apps installed into it, npm/gem/pip pattern — matches what elita is). Other candidates: single self-contained binary per app (go style), docker run, hex/mix for the erlang-native route. Each implies a different audience. Decide later, not load-bearing for minimal napo.

Elita ships as an installed runtime, ruby-and-rails style:

    brew install elita
    elita install napo
    elita napo

The image = the running elita on anyone's machine: agents born, living, talking, watchable. Apps (napo first) install INTO the runtime — markdown folders, nothing more. This is the product surface, the "installable" in the momentum plan. What it needs:

- packaging: single binary (escript/burrito over the BEAM), brew formula
- app install: elita install <app> fetches an agent folder; elita <app> boots it
- stay up: node persists independent of any REPL; agents live between conversations
- attach: talk to ANY living agent by name (chat.ex is the seed but locked to its boot agent)
- watch: agent messages live (Log's colored stream is the start)
- grow: napo writes markdown + spawns into the SAME running node — no restart, the app appears around you

## Minimal napo (the seed to grow)

Smallest napo that demonstrates the whole idea:

DECIDED 2026-07-02 — napo makes napos. No write tool, no engine changes. spawn already decouples name from config (`do_spawn(name, get(args, "configs", [name]), state)`): napo spawns children named for the pieces (poet, checker) with configs: ["napo"] — same markdown, narrower problem via ask/tell. Species = napo instances differentiated by the problem handed to them. Recursion is not a v-next feature; it IS the mechanism from v0.

First green:
1. agents/napo.md — tools: spawn, ask, tell. Prompt: if the problem is bigger than you, spawn napos named for the pieces, delegate, recombine.
2. one tape test shaped like test/unit/doctor_test.exs: ask napo a toy problem, verify the answer. Record once on haiku; cassette is the spec.

Parked: anonymous children (spawn without name, engine gensyms one) — useful when recursion goes deep and naming becomes bureaucracy; v0 names children for attach/watchability. Anonymous inline definitions rejected — files/config reuse covers it.
Persistence of grown agents to disk ("the app you keep") is a later, separate concern.

## El (recon 2026-07-02): the REPL chassis already exists

~/dev/self/el is a WORKING daemon control plane (v0.1.104, tests green): persistent named node (el@127.0.0.1) + EPMD, El.Registry for named processes, ask/tell = GenServer call/cast (identical semantics to elita), client CLI attaches to running daemon, session metadata API, mix release builds a real binary. Today its "agents" are Claude Code PTY sessions; elita's are markdown GenServers — same architecture, different brain plugged in. So el-as-elita-REPL is a backend swap (daemon spawns Elita.start_link alongside/instead of Claude PTYs), days not weeks. The image's hard parts (stay up, attach by name, survive REPL exits) are el's tested core. Key files: lib/el.ex, lib/el/session/{api,registry}.ex, lib/el/cli/daemon.ex.

## v0 BUILT & PROVEN LIVE (2026-07-02)

napo v0 works, phased like speck. Zero engine changes — all markdown. Files: agents/elita/napo.md (orchestrator), agents/elita/attempt.md, agents/elita/split.md; reuses agents/elita/judge.md. Live test: test/unit/napo_test.exs.

Architecture:
- napo.md orchestrator (tools: spawn, cast, set, get; includes attempt, split, judge): spawns ONE shared judge, sets attempts=0, casts to attempt.
- attempt.md (tools: ask, set, get, cast — NO spawn): solve whole problem, ask shared judge (never self-grade), count attempts. On judge yes -> return. After 3 judge-no AND own name == "napo" -> cast to split. If name != "napo" (a spawned child) -> never cast; return best answer (leaf).
- split.md (tools: spawn, ask — the ONLY phase that can spawn): break into 2-3 subproblems (hard cap 3), spawn a child per subproblem with a UNIQUE facet name, configs ["napo"], ask each, combine.

Why phased (speck pattern via includes + cast + active-config filtering): the split strategy is HIDDEN from the model during attempts, so it can't split prematurely and can't skip trying. Structural gate, not a prompt plea.

Proven live:
- Generalizes with domain-neutral prompt: SaaS pricing -> demand/economics/positioning; 2008 crisis -> trigger/propagation/structure; rate limiter -> algorithm/topology/contract. Discovers facets, not copied hints.
- Easy problems stay in attempt, judge yes on attempt 1, no split.
- Judge-gated retry: judge no -> refine -> judge yes by attempt 2 (lenient judge absorbs most problems in <=3 tries; split is the rare frontier — on thesis).
- Split path deterministically verified (judge forced always-no, threshold 1): root attempts -> cast to split -> 3 unique children (not "napo") -> each runs attempt -> ZERO grandchildren -> combine. Exact spawn count 4 = 1 judge + 3 children.

Bugs found & fixed:
- children reused name "napo" -> registry collision + defeated leaf-guard. Fix: unique facet names.
- attempt phase had spawn tool -> leaf children spawned grandchildren (runaway, blew fan-out cap). Fix: removed spawn from attempt; only split can spawn; children are true leaves by construction. Depth bounded to 1, fan-out <=3.

Open / next:
- Judge is lenient — split rarely triggers naturally; fine for v0 (matches "better models = shallower trees") but the split branch only fires on genuinely hard/multi-part problems.
- Recursion is depth-1 in practice (children are leaves). True multi-level recursion (children that themselves split) is the next layer — needs a depth bound.
- Recombination is still concatenate/synthesize; the hard recombination-rot problem (local green != global green) untouched.
- Not yet taped. Tape only once a scenario is worth freezing.

## Status

2026-07-02: napo v0 built and proven live (phased attempt/split, no engine changes). EL IS THE REPL — el (dev/self/el, erlang comms) becomes elita's front door, irb/iex lineage: brew install elita, type el, you're inside the image talking to agents. Dev sequence: mix test → el → brew. Napo grows in the test harness (tape records every experiment, replays free — napo born cheap), then lifts into el as living image, then brew wraps it. Next: recursion depth + recombination.

## Context

Full thesis and category analysis: thesis.md (formerly YC.md). YC parked — funding is a consequence of momentum, not a goal. Strategy: keep the job, build to installable, let momentum decide.

## Toward depth: tree-forming problems (research 2026-07-02)

v0 is depth-1 because the leaf-guard is NAME-based (only an agent literally named "napo" may split; children get facet names so they never recurse). To get real trees, replace the name-based guard with a DEPTH bound: split spawns children with configs ["napo"] AND a depth value in state; the attempt phase may cast to split only if depth < max (e.g. 3). Natural stopping already exists — a node stops splitting the moment one attempt satisfies the judge (bounded working memory per node).

What makes a problem TREE-forming (not flat), from research: (1) bounded working memory per node — each level isolates ~3-5 independent levers, too many to hold at once; (2) heterogeneous sub-skills per level — different expertise/data at each depth; (3) scale-driven scope reduction — abstract at top, concrete at leaves. Flat problems lack repeated heterogeneity + repeated scope reduction.

Catalogues to mine: divide-and-conquer algorithms; HTN planning (compound task -> methods -> primitive actions); MECE issue trees (McKinsey/Minto, 3-5 branches/level, stop when leaf is answerable); Polya auxiliary-problem decomposition; GOMS (goals->subgoals->operators); functional decomposition (system->subsystem->module->component); work-breakdown structure.

Best first depth test — PROFIT DECLINE issue tree (LLM-answerable, mechanically checkable, genuine depth 4):
  L1 Profit = Revenue - Cost
  L2 Revenue = Price x Volume x Mix ; Cost = Fixed + Variable
  L3 Price(discounting), Volume(customers, frequency), Mix ; Fixed(labor, rent), Variable(COGS/unit, fulfillment)
  L4 customers(acquisition, churn, retention by cohort), COGS(commodity inflation, supply chain, sourcing), labor(wages, productivity, headcount)
Recurses because each node's levers are independent and need different data — no single level answers "why".
Other good depth>=3 candidates: strategic goal cascade; product roadmap (theme->epic->feature->story->task); system architecture decomposition; research-question decomposition; onboarding-abandonment root-cause tree.

Next build: depth-bounded recursion (depth counter in state, max ~3), then run Profit Decline live and confirm a >=3-level tree forms with bounded fan-out per node.

Report done.

## Problem catalogue (mined 2026-07-02)

Candidates for napo tests. Requirements a candidate must meet: class over data (same decomposition, any instance — the tree is a reusable app); LLM-suited nodes; judge check cheaper than solving; foreseeable reference tree to diff against; natural depth >=2, fan-out 2-3. NOT suited: raw data crunching (sorting etc. — LLM judge can't verify big outputs; verification as hard as solving).

Ranked list:

1. Profit decline root-cause (IN FLIGHT): profit -> revenue(price/volume/mix) + cost(fixed/variable) -> churn/COGS/labor. Judge: MECE + consistency vs financials.
2. Contract risk review: 40-clause SaaS agreement -> obligations / financial terms / liability / compliance+IP / termination. Judge: red-flag checklist match.
3. Incident postmortem (5-whys tree): outage -> hardware / config drift / operational, each "why" branches. Judge: causes must match logs/metrics/timeline.
4. M&A due diligence: data room -> financial / legal / tech / operational / commercial. Judge: risks grounded in doc excerpts, misses vs truth set.
5. Curriculum design: course -> foundational / intermediate / capstone; judge checks prerequisite ordering + Bloom's progression.
6. Differential diagnosis: symptoms -> viral / bacterial / atypical branches with discriminating tests. Judge: vs established diagnosis trees.
7. GDPR gap analysis: pipeline -> subject rights / consent / protection / third-party / privacy-by-design. Judge: vs GDPR articles.
8-10 (harder to judge, parked): forensic incident deep-dive, monolith->microservices plan, market entry strategy.

NEXT PROOF = structure reuse — after napo grows a tree on instance A, ask the SAME running cluster instance B (different data); reuse = zero new spawns, asks route to existing children. The structure, not the answer, is the deliverable.

### Mem as blackboard (idea 2026-07-02)

Global tree_* keys mean any node can read any other node's slot — cross-tree reads via shared mem without message edges; spawn topology stays a tree. Also seeds backtracking: a re-split reads what the failed branch already learned. Unbuilt, parked.

## Day 2 results (2026-07-02 night)

Commits on wip: 27fa2ec depth-bounded recursion (global depth ETS, whoami tool); 9207137 receive_timeout 120s in lite.ex (Req default 15s was killing all long runs); 7d75c58+b295d1d engine resilience (set/ask/tell/cast return error strings on bad args, not crash); a87a614 test/napo folder; 7c7566e tell-based split + contract shape test GREEN LIVE; 717a194 doneness prompts.

PROVEN LIVE, no rigging: napo splits naturally on big-input problems. Contract MSA review (35 clauses) split 4-of-5 runs into ~3 facets (financial/liability/operational or /data). Judge honestly rejects "nothing missed" claims. Children each judged yes, wrote tree_ slots. Shape test green live (94s).

Learned: split honesty comes from INPUT VOLUME (one head can't hold it), not question ambition. Profit-decline = one-message problem, judge passes it (shallow+resilient = fine). Sorting-type data problems bad fit: LLM judge can't verify big outputs.

Architecture landed: tell-based split (work flows down by tell, answers live in mem tree_ keys, only leaves compute, no blocking asks up the tree, single overall timeout at test boundary). Doneness: child tells parent done, parent combines when all children done, tells its parent; status asks answered from mem; test polls root "are we there yet" (committed, NOT yet verified live).

Tape gap (task open): sparse cassettes miss on async tree replay — message order diverges between record/replay (recordings preserved: /tmp/contract_full_recording.json 116 entries, /tmp/contract_useless.json 15). Engine-side matching strategy needed. play.ex:21 crash on missing cassette still unfixed.

Known bug: haiku sometimes takes a 4th attempt instead of splitting at threshold 3 (prompt compliance, nondeterministic).

### Day 2 close

(1) Replay solved: agent-tagged entries, sparse content-match (strip agent+n), turn count n tiebreak, ordered claims, stick-at-last.
(2) Sample tests (employment/vendor/lease) taped sample.json, replay free ~10s each.
(3) Judge stateless (fresh history per ask) → order-independent recordings.
(4) Commits ccc469f, c6adc9c, 919d829 pushed wip PR #7.
(5) Open: contract_test.exs needs recorded run.

Next: verify doneness live; samples tests (run discovered structure on new data — the reuse/program proof); tape engine for trees; then more catalogue problems.
