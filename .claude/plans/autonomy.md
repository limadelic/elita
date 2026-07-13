# Autonomy Probe — Proven Real, Live-Only by Nature

## Status
**VERIFIED REAL** (rec15): Unscripted round-trips between yorick and banquo, autonomous replies with el tell commands.

## Why Live-Only
The autonomy loop executes outside the cassette tape boundary:

1. **Cassette boundary**: I/O text capture (what appears on screen/in logs)
2. **Autonomy beat**: Live claude bash execution + message injection to receiving agent

### The sequence:
- ✓ Wrapped claude receives envelope "[from banquo]\nknock knock" (tape captures text)
- ✗ Wrapped claude executes bash `el tell banquo who is there` (tape CANNOT capture this)
  - Stub claude outputs text, but doesn't run bash
  - CLI tell never connects to banquo
  - banquo's inject never happens
  - banquo's autonomous reply never occurs
- ✗ Replay fails structurally: bash execution is outside tape scope

### Evidence
- rec15: Live claude with system prompt priming → autonomous loop works, unscripted round-trips
- TAPE=replay: Cassette exists but replay red at assertion (banquo never gets injected message)
- No cassette written: TAPE=rec mode only captures I/O, autonomy execution is live-only

## Design Decision
- Keep `@autonomy` tag excluded from default profile (`cucumber.yml`)
- Document as "live-only" in feature and plans
- Do not attempt fake cassette (violates Cartman audit: "guard_live intact")
- Run against live claude only for verification

## Implementation Details
- System prompt: "You have bash. When envelope arrives... respond by running el tell NAME answer."
- Transport: El.Wrap.Remote.tell with connect-first delivery chain
- Sender identification: EL_FROM env var, defaults to CLI node name
- Envelope format: "[from SENDER]\nmessage"
