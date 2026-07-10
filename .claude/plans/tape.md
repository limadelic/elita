# Tape Extraction & Cache

## Vision

Tape is one engine serving two uses: test replay (today) and shipped decision
cache for agents (new). The only fork is miss policy: raise (tests), go live
(prod fast-path), swallow (mock). Matcher, store, claims are shared verbatim.

Cache is precached — authored and versioned with agents, read-only at runtime.
JSON stays: human-authored entries are the point.

## Slices

### 1. Extract tape to its own app

- Move `apps/elita/lib/tape*` → `apps/tape` (umbrella app), `mv` to keep history
- Cassette dir already configurable via CASSETTE_DIR env (qa) — keep, don't reinvent
- Cassettes live in `features/cassettes`, suite is cucumber
- Zero elita imports already — move should be mechanical
- Gate: cucumber green, mix lint clean

### 2. Pluggable miss policy

- `on_miss` option: `:raise` (default, current behavior), `:live`, `:swallow`
- `:live` — call the wrapped fn, return response (no recording; cache is shipped)
- `:swallow` — return a benign empty response
- Gate: existing tests untouched + one acceptance flow extending an existing
  test proving live fall-through and swallow

### 3. Shipped decision cassette for el

- el wraps llm calls with tape `on_miss: :live`, cassette shipped with agents
- Entries: matcher on last message → recorded tool-call response, `times: always`
- First entry: `el claude` → puppet tool call, skipping the llm
- Gate: acceptance flow — matched command replays at $0, unmatched goes live

## Non-goals

- No runtime cache writes, no eviction, no TTL
- No binary stores, no Cachex/DETS
- No fuzzy caching of conversational history — last-message matching only
