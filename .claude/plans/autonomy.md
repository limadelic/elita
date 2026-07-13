# Autonomy Probe — #41 Live Tell-Back Without Script

**Question**: Will a live Claude react to a tell envelope WITHOUT a scripted reply step, and what primes it?

## Scenario Draft (Gherkin, Zero Scripted Reply)

```gherkin
@malko @wip
Feature: Ghost Autonomy

  Scenario: Ghost replies to knock without prompt
    * > el claude ghost
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el claude hamlet
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * hamlet> tell ghost knock knock
    * hamlet:
      | knock knock |
    * ghost:
      | from hamlet |
      | knock knock |
    * hamlet:
      | who's there |
```

**Key difference from malkovich.feature**: No `ghost> tell hamlet who's there` scripted line. Assertion is purely on hamlet's side: agent waits for the unprompted reply to appear in hamlet's transcript via `verify_lines` (el_steps.rb line 93–102, case-insensitive match on "[from ghost]" + "who's there").

## Instruction Channels (Priming Options)

### Option A: Inline System Prompt (Preferred)
- **Mechanism**: Pass `-s "When you see a tell envelope like '[from X]\\nmessage', reply with 'tell X <response>'."` to `el claude ghost` spawn
- **Pros**: Reversible, isolated to one agent, no filesystem clutter, tests pure instruction
- **Cons**: System prompt injection point not yet wired in spawn code (needs one-line edit to pass-through)
- **Pick**: This. It's the seam.

### Option B: CLAUDE.md in Shared Temp
- **Mechanism**: Create a CLAUDE.md at runtime in a temp dir, spawn both agents there
- **Pros**: Existing CLAUDE.md etiquette already read by Claude Code on startup
- **Cons**: Requires setup per-run, both agents must share cwd (cross-contamination risk)
- **Risk**: Breaks lane isolation if agents drift to familiar cwd

### Option C: No Priming (Baseline)
- **Mechanism**: Spawn with zero guidance, agent sees envelope cold
- **Pros**: Tests if autonomy is emergent (no help needed)
- **Cons**: Likely fails; if it does, doesn't teach us which channel works

**Recommendation**: A (inline system prompt). If agent ignores prompt, retry with B. C is the failure baseline.

## Recording Plan (Tape Skill)

**Cassette**: `test/cassettes/malko/autonomy.json` (new, feature-keyed)

**Recording process**:
1. Clean cassette: Not needed (new file)
2. Fire detached in scratchpad (machine exclusive):
   ```bash
   nohup env TAPE=rec bundle exec cucumber features/malko/autonomy.feature:N > /tmp/autonomy.log 2>&1 &
   ```
3. Poll log for completion: `grep -A1 "Finished in" /tmp/autonomy.log`
4. One live take. Approval discipline: record complete, then adjust assertion text verbatim from tape (tape.md line 58–60)
5. Replay: `TAPE=replay bundle exec cucumber features/malko/autonomy.feature` — must be $0, sub-second

## Failure Modes & Teaching

| Outcome | Signature | Teaches |
|---------|-----------|---------|
| **Success** | `hamlet:` shows "[from ghost]" + "who's there" | Autonomy works. Which channel? Isolate via lane re-record (with/without prompt). |
| **Ignores** | `hamlet:` shows only "[from ghost]" + "knock knock", no reply | Agent treats envelope as noise. System prompt wasn't read, or etiquette missing. |
| **Prose reply** | `hamlet:` shows ghost's explanation ("I'll tell you...") instead of `tell` syntax | Agent understands tell, but doesn't parse envelope trigger. Adjust prompt wording. |
| **Wrong target** | `hamlet:` shows reply sent to wrong agent | Agent parsed envelope but misread sender field. Envelope format issue or prompt ambiguity. |
| **Timeout** | Scenario hangs after envelope shown | Agent waiting for human input. System prompt didn't override REPL mode. |

## Open Questions for Amigos

1. **System prompt pass-through**: Does spawn code already wire `-s` flag, or is that a one-liner?
2. **Tell syntax discovery**: If agent autonomously replies, does it call `tell hamlet ...` or invoke it differently (el command, manual puppet.put, something else)?
3. **Lane collision**: Running two live claudes (ghost + hamlet) on same machine — any epmd/distribution conflicts we haven't seen? (bowling.md line 71–73 lists full-suite collisions; this is minimal subset.)
4. **Etiquette scope**: Does CLAUDE.md in agent's cwd actually affect live claude behavior, or only Claude Code? (napo.md § "Agent setup" might clarify.)
5. **Inversion viability**: If autonomous reply fails here, does that invalidate the ask-on-tell inversion plan? Or just means prompt-priming is upstream task?

## Success Criteria

- **Green**: Cassette replays $0. Assertion "who's there" appears in hamlet's transcript with case-insensitive match. No manual tell-back step in feature file.
- **Push**: Commit feature + cassette only. No code edits yet (assume Option A is a one-liner, deferred to next task if blocked).
