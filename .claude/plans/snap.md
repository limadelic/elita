# SNAP MOVIES: Record & Play Claude Output Stream

## Vision
Record Claude's output stream at the matrix seam as an ordered sequence of byte chunks ("movie"), then play it back through the same seam so Spawn/Watch/Session/pty consumers run against a filmed Claude at $0 replay cost.

## Current State
- **snap.rb**: captures final settled 80x24 frames post-ANSI-parse, verifies presence of golden text blocks
- **Tape**: LLM-level cassette (request/response, keyed by agent+message); no frame-by-frame recording, no playback of stream
- **Gap**: no byte-level recording of Claude's output flow, no mechanism to stub the port and feed recorded bytes back

## The Seam: Where to Record
**File**: `apps/matrix/lib/matrix/pty/relay.ex:data/3`

```
def data(pty, data, %{port: port, out: out, raw: raw, taps: taps} = state) do
  binwrite(out, data)         # line 11: stdout
  dump(raw, data)             # line 12: raw log
  notify(taps, data)          # line 13: tap notify
  respond(port, pty, data, state)  # line 14: handler process
end
```

Bytes arrive in `data` parameter. This is where Claude's output enters the system. All downstream consumers (screen/80x24 grid, handlers, watchers, taps) depend on bytes flowing through here.

## Design: Record Phase

**New module**: `Matrix.Movie.Record`
- On live run (not replay):
  - Before spawn launches Claude, register the dispatcher's `data/3` as a callback hook
  - Each call to `data(pty, data, state)` appends `{timestamp_ms, data}` to an in-memory accumulator (e.g., Agent or ETS table)
  - At process exit, flush accumulator to cassette under `"movies"` → `"agent_name"` → `[{chunk_index, chunk_bytes}, ...]`

**Integration point**: `Matrix.Pty.Dispatch.info/2` (line 11-15)
- Minimal: wrap the existing `data/3` call with a record hook

**Cassette shape** (extend Tape.Store):
```json
{
  "tape": [{q, a}, ...],
  "screens": {...},
  "movies": {
    "agent_name": [
      {"i": 0, "chunk": "byte_string_0"},
      {"i": 1, "chunk": "byte_string_1"}
    ]
  }
}
```

Order matters; no timestamps needed (tests don't care about real timing, just presence/order).

## Design: Playback Phase

**New module**: `Matrix.Movie.Play`
- On replay run (tape=replay), before Spawn launches Claude:
  - Look up cassette entry `movies.agent_name`
  - Stub the port: replace real port with a fake that feeds chunks on-demand
  
**Stub port strategy**: a Gen.Server named `Matrix.Movie.Player` per pty
- `open(pty, agent_name, cassette)` → starts player Gen.Server
- Player holds chunk queue + current chunk state
- Spawn's `port.command(pty, ...)` calls → intercept, no-op (don't write to real port)
- Spawn's receive loop waits for `{pty, {:data, data}}` → Player sends chunks back one-by-one
- At end of queue, send final `{pty, :closed}` to trigger graceful shutdown

**Seam**: `Matrix.Pty.Boot.init/1` (opens real port)
- Conditionally: if TAPE=replay, call `Movie.Play.open(pty, name)` instead; bind fake port pid

## Smallest Slice: Proof-of-Concept

**Phase 1: Record One Session** (1 live run, $0 after)
1. Add `Matrix.Movie.Record` module: accumulator + cassette flush
2. Bind hook in `Dispatch.info/2`: call record before `data/3`
3. Cassette shape: add `"movies"` key to existing tape format
4. Run one live malkovich scenario: `TAPE=rec mix cucumber features/malko/malkovich.feature:5`
5. Verify cassette has `"movies"."malko"` array of chunks

**Phase 2: Play One Session** ($0 cost)
1. Add `Matrix.Movie.Play` stub port
2. Add conditional in `Boot.init/1`: detect TAPE=replay, use Play instead of real port
3. Run same scenario replay: `TAPE= mix cucumber features/malko/malkovich.feature:5`
4. Assert screen shows same text, no LLM call made

**Success criteria**:
- Cassette file contains recorded chunks
- Replay feeds chunks through dispatcher without calling real Claude
- Screen frame emerges identically (proof that bytes flowed correctly)
- One test assertion passes (e.g., snap grab matches golden)

## Out of Scope (Next Layer)

- **Multi-agent movies**: portal scenarios with 2+ Claudes (3-path design, requires session→movie indexing)
- **Interactive timing**: keystrokes mid-stream, user interleaving (tape is pre-scripted; timing preserved but not replayed)
- **pty window resize**: SIGWINCH signals (live-only; frozen in replay)
- **Cross-node movies**: distributed Claude over mesh (El.Distribution scope, not matrix)

## Proof of Concept Deliverable

One cassette file with `"movies"` key populated from live session; one passing replay run that consumes it. No UI, no export, no multi-session indexing. Just the byte stream recorded and played back at the seam.

## Money

- **Recording**: 1 live run, sanctioned, $0.23 cost (Haiku Claude for malkovich scenario ~2.3s from CLAUDE.local.md)
- **Playback**: infinite $0 replays after (tape replay cost = file I/O only)
- **Coverage gain**: Spawn/Watch/Session/Log layers move from 0% to replay-verifiable with filmed claude
