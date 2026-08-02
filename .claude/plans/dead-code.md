# Dead Code Plan

Source: coverage run 49e8749c (total 31.58%, 67 modules at 0%).
Method: 0% coverage → caller sweep (4 scouts) → adversarial verify (cartman: dynamic concat, formatter tuples, atom apply, CLI routes, cassettes, agent configs, git history).
Rule: one file per kenny slice, gates + cukes green each, delete only after boss approves this list.

## Kill List (8 modules, ~245 lines)

| Module | File | Lines | Proof |
|--------|------|-------|-------|
| Adapt | apps/elita/lib/llm/adapt.ex | 91 | zero refs anywhere |
| Color | apps/elita/lib/utils/color.ex | 7 | zero refs anywhere |
| Shape | apps/elita/lib/llm/shape.ex | 32 | zero callers; only imports Forge |
| Forge | apps/elita/lib/llm/forge.ex | 27 | only caller is Shape (dead) — delete after Shape |
| El.Log.Format | apps/el/lib/el/log/format.ex | 30 | not registered as formatter/handler anywhere incl. matrix |
| El.Log.Reply | apps/el/lib/el/log/reply.ex | 20 | handle/2 never invoked |
| El.Commands.Boot | apps/el/lib/el/commands/boot.ex | 5 | born e1135d7a, never routed in El.CLI |
| El.Commands.Chat | apps/el/lib/el/commands/chat.ex | 33 | moved in 8a5938c4 "zero external callers", never routed |

## Order

1. Adapt, Color, El.Commands.Boot, El.Log.Reply — independent, any order
2. Shape then Forge — dependency order
3. El.Log.Format, El.Commands.Chat — last; Format has lane-history noise (dude lane once ruled a log/format.ex a live formatter — cartman found no registration here, but verify compile output clean), Chat was deliberately moved cross-app recently

## Not Dead (context)

Remaining 59 zero-coverage modules all have callers — live-only territory (puppet chain, REPL, tunnel, signal, spawn/session paths) unreachable under $0 replay. They are coverage work, not dead code.
