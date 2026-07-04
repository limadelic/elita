# Taping napo

Napo splits into children, children recurse, doneness bubbles up. Taping that tree is its own beast.

## Test shape

- One file per problem in `test/napo/`, 4 tests: 1 shape (napo forced to split) + 3 samples
- Shape test: `tell :napo, problem` then poll `:mem_depth_global` for `tree_napo` + ≥2 child `tree_*` keys
- NEVER `ask :napo` in a shape test — test blocks on napo while napo blocks asking children, deadlock
- `@tag timeout: 1_200_000`, poll bound 1150s — a full split live runs anywhere from 40s to 15+ min depending on judge mood

## Timeouts

- Two recordings died red on "Timeout after Ns" with a HEALTHY log — children mid-work, clock too short
- Autopsy the log before touching code: split happened? children notifying napo? then it's the bound, not a bug

## Recording behavior

- Output arrives in multi-minute BURSTS — a log static 5+ min with live pid is normal, killed a healthy run once for this
- Check staleness by mtime (`stat -f "%Sm"`), not by staring at size
- Judges are stateless (fresh `[user(msg)]` per verdict) — keeps recordings order-independent
- Turn count `n` is a tiebreak in replay, not a filter — shared-agent history varies with async ordering

## Audit a fast green

- 40s green looked fake, was real — judges accepted first attempt everywhere
- Proof: `git diff --stat` cassette (+1284 lines), `grep -o '"agent": *"[a-z_]*"' | sort | uniq -c` showed napo + 4 facets + judge
- Trust the diff, not the clock
