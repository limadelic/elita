# claude_wrapped

## STATUS 2026-07-06 late — HUMAN TYPING WON, matrix demo, one-test suite

Mike's keyboard finally works end to end. Three stacked causes, each
nailed by EL_TRACE evidence: (1) six ghost sessions from failed runs
were eating keystrokes (purged; sessions need exclusive tty ownership
— resident-node argument); (2) file.read(/dev/tty, 1024) held bytes
hostage on real terminals — og el's byte-at-a-time read restored
(753e4af); (3) his terminal delivers Enter as 0A, claude submits only
on 0D — input-hook seam translates \n→\r (127974a): the middleware's
first production job. Earlier: input race killed via escript
-noinput (9a32b5a); `el` command relinked from stale homebrew og el
to elita launcher, symlink-safe via readlink -f (72d4ef8).
E2E wiped to ONE linear session test (29e799f): welcome → /model
haiku → 1+1 → /effort → /exit, 55s, prints its own bill (sessions: 1,
prompts: 1 haiku). Cost law in CLAUDE.local.md.
Matrix demo (1c6685a): apps/el/test/e2e/matrix.exs ghost-types Neo lines
into a live session char-by-char, Ctrl+U wipes, zero prompts. Ghost
hands proven live: remote inject drove /color, /model→haiku, 1+1 in
Mike's own terminal. fya research: claude emits ESC[?2004h when its
input reader attaches — free readiness signal for the supervisor.
EL_TRACE=path hex-logs header (tty_source) + every stdin byte.
Next: dude on the taps, demo recording, resize/erlexec, resident node.

## STATUS 2026-07-06 night — TRANSPARENCY WON, flagship landed, 16/16

THE bug of the day: BEAM prim_tty owned :user stdin and line-edited
away every escape sequence (arrows, history, paste, menu keys) before
our reader saw them — one cause behind five "different" symptoms.
Fix bdc93f1: PtyReader opens /dev/tty raw FIRST, :user only as
fallback (og el knew this trick). Baseline matrix had convicted the
wrap: plain claude 6/6 in same harness, wrap eating escapes.

FLAGSHIP (cartman-verified): probe node injects /model + 4x \e[B +
Enter into a live session → footer flips to "Haiku 4.5 with low
effort" → remote model switch by pure inject. #17 done. REMOTE suite
check asserts it. Menu-by-inject unparked.

Suite 16/16 (BACKSPACE added; arrows/history/paste unlocked but
non-echoed edits aren't expect-assertable — Mike's fingers are final
validation). Middleware seams landed (input hook + output taps,
identity defaults, 6e46781). Lesson of the day: kennys inflate
verdicts under pressure — verification agents demanding raw capture
excerpts are mandatory, adversarial cartman pass before believing
anything big.

## STATUS 2026-07-06 evening — hardened, 15/15, menu-by-inject parked

Suite grew 11 -> 15 checks (MODEL, RESTORE, REMOTE, honest ORPHANS
demanding zero). Day's kills: 251 zombie orphans (rows-0 size bug +
process-group leak, both fixed at source, machine was overheating);
mouse-event garbage after exit (xterm private modes now reset on every
exit path); /model menu never rendering (claude emits DSR ESC[6n and
waits for cursor reply — el now ANSWERS the query itself: first real
middleware muscle); injected arrows dead (tell appended \r to control
bytes — raw passthrough fixed).

PARKED: menu-by-inject. Menu renders but ignores ALL synthetic input
(CSI \e[B, SS3 \eOB, filter text, digits) across 5 attempts. Suspect
Ink input handling vs script-owned pty; revisit with erlexec. Doesn't
block supervision: model set at spawn (--model), runtime dials proven
= inject messages, /effort flip, /exit kill switch. No /color or
runtime /theme exists in claude (settings.json, startup only).

Supervision doctrine agreed with Mike: EYES on output (tap only, never
rewrite the render), HANDS on input (transform/veto/expand allowed).
Next: middleware seams in pty.ex (input hook + output observers,
identity default, suite stays green).

## STATUS 2026-07-06 morning — POC DONE, suite-verified

Branch poc, all pushed. `bin/el claude` = real Claude Code TUI, full
size, slash commands, /exit; `el tell claude "msg"` injects from any
shell (distribution: node el_claude@127.0.0.1, cookie elita, fallback
to Elita agents). Acceptance = apps/el/test/e2e/wrap.sh: 11/11 green, ~$0:
RENDER SIZE_120x40 SIZE_80x24 INPUT SUBMIT KILL CLEAN SLASH EXIT
INJECT TELL. No hand-testing needed.

Bugs found+fixed by the harness (units caught none): spawned self()
mailed stdin to nobody; {:spawn, string} tokenization shredded sh -c;
BEAM-side /dev/tty size read fell back 24x80 (fix: bin/el launcher
exports EL_ROWS/EL_COLS from shell stty); inner pty cooked mode ate
slash commands (fix: stty raw on inner). Typed "exit" doesn't quit
plain claude either — wrap matches baseline; /exit is the command.

NEXT: supervised mode (dude on the tap: session JSONL + live bytes for
liveness/timeouts); resize (SIGWINCH — needs owning pty → erlexec);
daemon/resident-node decision (agents need a place to live; escript
one-shots stay as thin clients); codex portability (cmd is already a
parameter).

Third el mode: interactive Claude Code inside a PTY that elita owns.
Transparent to the human — full TUI — but elita taps the output and
injects input. Foundation for dude-supervised sessions (separate plan).

## Modes

| Mode       | Runs as                                      | Status    |
|------------|----------------------------------------------|-----------|
| elita      | Elita GenServer, Lite API, tape-gated        | working   |
| headless   | Agent.Session, `claude -p` port              | working   |
| wrapped    | interactive claude in PTY                    | THIS PLAN |
| supervised | dude consumes wrapped's tap + inject         | later     |

## Grounding (scouted 2026-07-05)

elita wip (clean, 5 ahead of main):
- el = escript, `El.CLI` → ask/tell → Elita GenServer via Registry
- agents-as-code: `apps/elita/agents/*.md` (yaml frontmatter: name, tools)
- no poc folders exist; root-level poc/ is collision-free

og el (proven Apr 2026, b15f693):
- `lib/el/pty.ex` — GenServer, ~100 lines, full source captured:
  - PTY: `Port.open({:spawn, "script -q /dev/null claude --dangerously-skip-permissions"}, [:binary, :stream, :exit_status])`
  - out: port data → `File.write` to `/dev/tty` (raw)
  - in: linked process reads `/dev/tty` byte-at-a-time → `Port.command`
  - inject: `handle_cast({:inject, msg})` → `Port.command` (same path as keys)
  - DI seams for Port/File → 21 mocked specs, no cassettes needed
- `el.sh`: `stty raw -echo -isig` + `trap 'stty sane' EXIT` before launch
- KEY: og el ran as a RELEASE DAEMON; bash wrapper did `bin/el rpc El.CLI.dispatch(...)`
  into the live BEAM. That's how a second shell reached the session.
  pty.ex was never wired into og production CLI.

## The two hard problems

1. Terminal ownership. escript's prim_tty owns stdio; pty.ex sidesteps
   it by doing all I/O on /dev/tty raw handles, with the shell wrapper
   setting raw mode BEFORE the BEAM starts. Port both pieces together —
   the .sh is load-bearing, not cosmetic.
2. Cross-BEAM inject. Wrapped session lives in the foreground escript
   BEAM; `el tell` runs in a fresh escript BEAM. Bridge = distributed
   Erlang: wrapped session starts a named node (EL_NODE plan aligns),
   tell connects and casts inject. POC may fake it with a local
   Node.connect between two iex shells first.

## POC

Branch `poc` off wip. Real code in apps/el — no side folders.

GOAL: `el claude` prints the Claude welcome screen and behaves exactly
like running `claude` in that folder. That's the whole POC.

- `el` alone = el chat (existing REPL, unwired)
- `el claude` = run claude here, wrapped (invisible plumbing)

Steps (each ≤5-min task):
1. Add `claude` command to El.CLI → PTY module ported from og pty.ex,
   elita style (single words, imports, pattern matching)
2. Shell wrapper concern: stty raw before BEAM (og el.sh trick) —
   figure out where that lives for an escript
3. Smoke: `el claude` shows welcome screen, keys work, exit clean
4. Findings written back into this plan

After the welcome screen works: inject from second shell, tap log,
then supervised.

## Integration (post-POC, post-blessing)

- `el claude [name]` in El.CLI → long-lived foreground wrapped session
- Wrapped module beside `agent/session.ex` as sibling session kind
- Register in ElitaRegistry so `el tell <name> <msg>` = inject — the
  existing verb reaches into a live TUI for free
- Requires el escript to start distribution when wrapping (EL_HOST/EL_NODE)

## Open questions

- launch verb: `el claude` vs `el <agent> --wrapped` (Mike's call)
- inject framing: raw bytes vs `msg <> "\r"` — POC step 2/3 answers
- escript vs release: og needed a daemon release for rpc; elita may get
  away with escript + distribution. If not, that's a bigger call.
- resize/SIGWINCH, Ctrl+C: punt; note behavior in POC findings

## Research (web, 2026-07-05)

Prior art agrees with our design; key lessons:
1. Relay bytes as-is, never re-render. TAP is BOTH channels:
   - session JSONL (~/.claude/projects/...) for content/history
   - the live byte stream for liveness: spinner, elapsed time, token
     count — a hung agent writes no logs; only the screen shows
     "running 6m" (Mike's point, and it's the 5-min-timeout signal)
2. Inject = bytes + `\r` (not \n). Multi-line = bracketed paste
   ESC[200~ ... ESC[201~ then \r.
3. Ink TUI probes TERM + window size; needs xterm-256color and real
   dimensions or it renders degraded/condensed. e2e harness must set
   cols/rows on the outer pty.
4. erlexec is the production-grade PTY (RFC4254, set TERM/size at
   spawn); ExPTY is WIP, avoid. `script -q` fine for poc.
5. Known macOS PTY leak in claude (--print never releases pty) — watch
   for orphans, kill on exit.
Tools studied: claude-pty-wrapper, claude-squad (tmux), claude-pee,
fya, claude-yes. Source cloned to ~/dev/ext/claude-pty-wrapper and
~/dev/ext/fya; recipes extracted:
- inject: type, settle delay, THEN \r (fya typing.go); multiline in
  bracketed paste; likely fix for exit-not-quitting
- resize: SIGWINCH → resize inner pty — needs owning the pty, so
  erlexec graduates from later-polish to next-step-after-poc
- exit ladder: Ctrl+C → SIGTERM 1s → SIGKILL, on the process GROUP
- restore: save prior mode, restore in finally + signal handlers Official stream-json/SDK beats PTY only for headless —
we already have that mode; wrapped is precisely the human+supervisor
case where PTY is right.

## Portability (Mike, 2026-07-05)

The wrap must stay CLI-agnostic: pure byte relay, command string is a
parameter. `el claude` / `el codex` / `el pi` = same pty module,
different exec. Tool-specific knowledge (session file location, busy
signals, exit commands) lives only in the supervised layer. Don't bake
"claude" into pty.ex — only the command module knows it.

## Later

- dude supervision on the tap (non-abiding detection, 5-min timeouts)
- ExPTY / erlexec replace the `script -q` hack
- works over claude code / pi / codex — wrap is the seam
