# el in elita — scope (per mike, 2026-07-04, pre-beach)

el = the attach layer. One uniform ask/tell in the repl; registry decides what kind
of mind answers.

## The two pieces (mike's words)

1. repl: "ask the doctor blah blah" → spawns that agent (spawn tool) in the cluster,
   asks it. Pure elita: markdown agent, OTP process.
2. repl: "tell rec to review pr 2345" → rec is a REGISTERED agent: a headless
   claude run el-style, pinned to a folder (e.g. rec folder on the work machine).
   Message crosses machines if needed (EL_HOST/EL_NODE work, shipped in old el wip).

Same verbs (ask/tell) for both. Caller never cares which kind.

## What this implies

- registry entries: local markdown agents (spawn on demand) + external registrations
  (name → node + folder + claude session)
- claude-as-port organ from old el (Session GenServer over claude_code) gets ported
  into elita as the external agent kind
- daemon: cluster survives repl detach (old el's daemon/attach trick)
- old el repo: NOT subtree'd. Donates organs only: claude port session,
  Daemon.Env/Connection (cross-machine), CLI-as-node attach. Its registry/routing/
  DETS store do not come over (elita ask/tell + tape already are those)
- old el keeps running untouched for the 9-5 until new el covers it

## Not now

- umbrella: only if el earns a real app boundary; start as modules inside elita
- auth/quota routing between machines: later, it's a boss agent (markdown), not engine

## Next direction: el as agent (pending PR #8 review)

Emerging focus (mike's closing signal, 2026-07-04). Agent.Router/Config/Manager
was regular programming at the tip of agents-all-the-way-down; right scaffold to
prove the wire. Per thesis, dispatch policy IS a PROGRAM: el.md's prose says "look
them up; registered → wake their claude in their folder; else spawn". Registrations
live in its ETS pouch, not env vars. CLI shrinks to pure transport. Eat the engine
from above once the wire is trusted.

**Nothing is decided until mike reviews PR #8.** This captures the grounding insights
that make this direction viable, not a commitment to execute it.
