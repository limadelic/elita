# Elui Migration: Matrix Becomes a Thin Backend Abstraction

**Goal:** Replace Matrix's hand-rolled PTY I/O and stty shell-outs with Elui, moving the tape seam into Elixir so door specs can assert at $0 replay cost.

**Current state:** Matrix is a GenServer managing raw I/O to Claude via Erlang's Port (spawned via `/usr/bin/script`). Taping happens outside Elixir (Ruby cucumber stub/screen-scrape). This is poisoned by node state every time because we record a live OTP system from outside.

**Target state:** Same code path, different backend. Elui.Backend.Test captures screens/state in-memory. Matrix.Movie.Play replays taped byte streams. ExUnit spec at door_test.exs asserts both LLM answers (tape: key) and pty output (movies: key) at $0.

---

## FIRST ORDER: Terminal-Within-Terminal Architecture

**The core insight:** Matrix becomes an Elui.App. Claude runs in a PTY, outputs ANSI bytes. Matrix parses those bytes into a screen model (Elui.Buffer cells), renders via Elui backend, forwards input events back down the PTY. Live terminal and test backend share identical code paths—same app, different rendering target.

### The Four-Layer Stack

```
┌─────────────────────────────────────────┐
│  El.Commands.Claude (CLI entry)         │
│  starts Matrix as subprocess            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  Matrix.Pty.App (Elui.App)              │
│  model: {terminal, pty, ansi_state}     │
│  update: PTY bytes → Ansi.feed → view   │
│  view: render parsed buffer to backend  │
└──────────────┬──────────────────────────┘
               │
      ┌────────┴─────────┐
      │                  │
┌─────▼────────┐    ┌────▼─────────┐
│ Matrix.Ansi  │    │ Elui.Terminal│
│ VT100 parser │    │ Double buffer│
│ → Cell grid  │    │ → Backend    │
└──────────────┘    └──────────────┘
      ↑                    │
      └────────┬───────────┘
         Backend.draw()
      ┌────────┴──────────┐
      │                  │
  ┌───▼──────────┐  ┌────▼─────────┐
  │Ansi backend  │  │Test backend  │
  │Real terminal │  │In-memory     │
  │+ stty        │  │+ capture     │
  └──────────────┘  └──────────────┘
```

### Layer 1: Matrix.Pty.App (new Elui.App)

Current Matrix.Pty is a GenServer; it becomes an Elui.App.

**Key points:**
- `init/1` spawns PTY, creates Elui.Terminal, starts Elui.Input
- `update/2` routes: PTY bytes → Ansi.feed → cell updates, then draw; input keys → encode → write to PTY; resize → SIGWINCH + autoresize
- `view/2` renders Ansi.buffer into frame via backend.draw
- **No more Dispatch.info, Gate, Buffer, DSR**: all logic is declarative event→model→view

Model structure:
```elixir
%{
  pty: pty_port,
  terminal: Elui.Terminal,
  ansi: Matrix.Ansi state (cursor, grid, escape buffer),
  input_session: Elui.Input.Session,
  taps: [pid],         # watchers
  watcher: Task,       # reads PTY async, sends :message events
  name: atom           # for taping
}
```

Event types:
```elixir
{:key, key, mods}                  # from Elui.Input
{:resize, width, height}           # from Elui.Terminal.autoresize
{:message, {:pty_data, bytes}}     # from watcher Task
:tick                              # from tick_rate
{:message, :quit}                  # synthetic, for /exit
```

Update dispatch (simplified):
```elixir
def update(model, {:key, key, mods}) do
  bytes = encode_key(key, mods)
  write_pty(model.pty, bytes)
  Matrix.Trace.record(bytes)
  {:ok, model}
end

def update(model, {:message, {:pty_data, bytes}}) do
  ansi = Matrix.Ansi.feed(model.ansi, bytes)
  notify_taps(model.taps, bytes)
  Matrix.Trace.record(bytes)
  
  updates = ansi.updates  # [{x, y, cell}, ...]
  terminal = model.terminal.backend.draw(model.terminal.backend_state, updates)
  
  {:ok, %{model | ansi: ansi, terminal: terminal}}
end

def update(model, {:resize, width, height}) do
  signal_pty(model.pty, :sigwinch, {width, height})
  
  # Rebuild at new size
  new_terminal = Elui.Terminal.new(backend: model.terminal.backend, 
                                     backend_opts: [width: width, height: height])
  new_ansi = Matrix.Ansi.init(width, height)
  {:ok, %{model | terminal: new_terminal, ansi: new_ansi}}
end
```

View: straightforward
```elixir
def view(model, frame) do
  # Render grid lines from ansi.buffer
  cells = Elui.Buffer.to_cells(model.ansi.buffer)
  Enum.reduce(cells, frame, fn {x, y, cell}, acc ->
    Elui.Frame.render_cell(acc, x, y, cell)
  end)
end
```

### Layer 2: Matrix.Ansi Parser (NEW, ~200 lines)

A stateful byte-to-cell parser. Handmade because Elui has no ANSI emulator (and we don't need one—just Claude's output).

**Scope:** What Claude actually emits (from Matrix traces + Ruby screen.rb):
- Printable ASCII + UTF-8
- `\r` (carriage return → x=0)
- `\n` (newline → y++, x=0, scroll if needed)
- `\t` (tab → x = next tab stop)
- **CSI sequences** `ESC[<params><final>` where final is:
  - `A/B/C/D` → cursor up/down/right/left by n (params is number)
  - `H/f` → cursor absolute: `ESC[row;colH` (1-indexed)
  - `2J` → clear screen
  - `K` → clear to end of line
  - (Colors/styles/bold: parsed, stored in Cell, rendered by backend or ignored by Test)
  - Other CSI: silently ignored

**File:** `apps/matrix/lib/matrix/ansi.ex` (~200 lines, detailed in code review)

Core structure:
```elixir
defmodule Matrix.Ansi do
  defstruct buffer: nil, cursor: {0, 0}, esc_buffer: nil, width: 80, height: 24, updates: []

  def init(width \\ 80, height \\ 24) do
    %__MODULE__{
      width: width,
      height: height,
      buffer: Elui.Buffer.empty(Elui.Layout.Rect.new(0, 0, width, height)),
      updates: []
    }
  end

  def feed(%__MODULE__{} = state, bytes) when is_binary(bytes) do
    String.graphemes(bytes)
    |> Enum.reduce(state, &process_char/2)
  end

  # Single character dispatcher
  defp process_char("\e", state), do: %{state | esc_buffer: "\e"}
  defp process_char(ch, %{esc_buffer: nil} = state), do: handle_direct(ch, state)
  defp process_char(ch, state) do
    seq = state.esc_buffer <> ch
    if escape_complete?(seq) do
      dispatch_escape(seq, %{state | esc_buffer: nil})
    else
      %{state | esc_buffer: seq}
    end
  end

  # Direct characters
  defp handle_direct("\r", state), do: carriage_return(state)
  defp handle_direct("\n", state), do: newline(state)
  defp handle_direct("\t", state), do: tab(state)
  defp handle_direct(ch, state), do: write_char(ch, state)

  # Escape sequences
  defp dispatch_escape("\e[" <> rest, state) do
    case parse_csi(rest) do
      {:cursor_move, dir, n} -> move_cursor(state, dir, n)
      {:cursor_abs, row, col} -> %{state | cursor: {col, row}}
      {:clear_screen} -> clear_screen(state)
      {:clear_line} -> clear_line(state)
      :unknown -> state
    end
  end
  defp dispatch_escape(_seq, state), do: state

  # Helper: write char at cursor, advance
  defp write_char(ch, %{cursor: {x, y}, buffer: buf, width: w, height: h} = state) do
    cell = %Elui.Buffer.Cell{symbol: ch}
    new_buf = Elui.Buffer.put(buf, x, y, cell)
    new_updates = [{x, y, cell} | state.updates]
    
    next_x = x + 1
    if next_x >= w do
      newline(%{state | buffer: new_buf, updates: new_updates})
    else
      %{state | buffer: new_buf, cursor: {next_x, y}, updates: new_updates}
    end
  end

  defp carriage_return(%{cursor: {_x, y}} = state) do
    %{state | cursor: {0, y}}
  end

  defp newline(%{cursor: {_x, y}, height: h} = state) do
    new_y = y + 1
    if new_y >= h do
      scroll_up(state)
    else
      %{state | cursor: {0, new_y}}
    end
  end

  defp tab(%{cursor: {x, width: w}} = state) do
    next_x = (((x + 8) / 8) |> trunc) * 8
    %{state | cursor: {min(next_x, w - 1), elem(state.cursor, 1)}}
  end

  defp move_cursor(%{cursor: {x, y}, width: w, height: h} = state, dir, n) do
    case dir do
      'A' -> %{state | cursor: {x, max(y - n, 0)}}
      'B' -> %{state | cursor: {x, min(y + n, h - 1)}}
      'C' -> %{state | cursor: {min(x + n, w - 1), y}}
      'D' -> %{state | cursor: {max(x - n, 0), y}}
      _ -> state
    end
  end

  defp clear_screen(state) do
    new_buf = Elui.Buffer.empty(state.buffer.area)
    %{state | buffer: new_buf, cursor: {0, 0}}
  end

  defp clear_line(%{cursor: {x, y}, width: w, buffer: buf} = state) do
    new_buf = Enum.reduce(x..w-1, buf, fn x_pos, b ->
      Elui.Buffer.put(b, x_pos, y, %Elui.Buffer.Cell{symbol: " "})
    end)
    %{state | buffer: new_buf}
  end

  defp scroll_up(%{buffer: buf, height: h} = state) do
    # Simple: shift lines up. Real impl would use Elui.Buffer API.
    # For now: reset to top (conservative, won't break)
    %{state | cursor: {0, h - 1}}
  end

  defp escape_complete?(seq) do
    seq =~ ~r/\e\[[0-9;]*[A-Za-z]/
  end

  defp parse_csi(rest) do
    case rest do
      <<n::binary-size(1), letter::binary-size(1)>> when letter =~ ~r/[A-D]/ ->
        {:cursor_move, letter, String.to_integer(n, 10) || 1}
      # ...more patterns for row;col, 2J, K, etc.
      _ -> :unknown
    end
  end
end
```

**Key property:** `feed/2` returns new state with `updates: [{x, y, cell}, ...]`. Pass directly to `backend.draw(updates)`. No intermediate screen object; cells flow straight to Elui.

### Layer 3: Backend Selection (Seam #1)

Refactor Matrix.Pty.Config.pick/2. Now selects between Matrix.Backend.Ansi and Matrix.Backend.Test:

```elixir
# Matrix.Pty.Config.pick/2
defp pick(nil, opts) do
  choose(replaying?(), exists?(opts[:name]))
end

defp choose(true, true) do
  {:matrix_backend, Matrix.Backend.Test}
end

defp choose(_, _) do
  {:matrix_backend, Matrix.Backend.Ansi}
end
```

**Matrix.Backend.Ansi** (thin wrapper, ~30 lines)
```elixir
defmodule Matrix.Backend.Ansi do
  def init(opts), do: Elui.Backend.Ansi.init(opts)
  def draw(state, updates), do: Elui.Backend.Ansi.draw(state, updates)
  def clear(state), do: Elui.Backend.Ansi.clear(state)
  def restore(state), do: Elui.Backend.Ansi.restore(state)
  # ... forward all 8 callbacks
end
```

**Matrix.Backend.Test** (in-memory + byte capture, ~50 lines)
```elixir
defmodule Matrix.Backend.Test do
  def init(opts) do
    Elui.Backend.Test.init(opts)
  end

  def draw(state, updates) do
    Elui.Backend.Test.draw(state, updates)
  end

  def record_bytes(bytes) do
    # Append to Agent:Matrix.Movie.Store
    Agent.update(Matrix.Movie.Store, &(&1 ++ [bytes]))
  end

  # ... forward all Elui.Backend methods
end
```

Matrix.Movie.Store: simple agent that collects byte chunks during replay:
```elixir
def start_link(opts) do
  Agent.start_link(fn -> [] end, opts)
end

def save(bytes), do: record_bytes(bytes)

def to_cassette do
  Agent.get(__MODULE__, & &1)
end
```

On teardown (Matrix.Pty.App exit), write accumulated bytes to cassette "movies" key.

### Layer 4: Resize Propagation (Seam #2)

No more DSR polling. Elui.Input + Elui.Terminal handle it cleanly.

In Matrix.Pty.App.update:
```elixir
def update(model, {:resize, width, height}) do
  # Signal PTY: send SIGWINCH
  signal_pty(model.pty, :sigwinch)
  
  # Rebuild parser + terminal at new size
  new_terminal = Elui.Terminal.new(backend: model.terminal.backend,
                                     backend_opts: [width: width, height: height])
  new_ansi = Matrix.Ansi.init(width, height)
  
  {:ok, %{model | terminal: new_terminal, ansi: new_ansi}}
end

defp signal_pty(pty, :sigwinch) do
  # :erlang.port_command(pty, ...) with SIGWINCH signal
  # OR use stty: "stty rows N cols N < /dev/tty"
  # Keep it simple: shell-out (same as today)
  :os.cmd(to_charlist("stty rows #{new_h} cols #{new_w} < /dev/tty"))
rescue
  _ -> :ok
end
```

### Layer 5: Test Backend Taping (Seam #3)

When replaying (`TAPE=replay` + cassette has "movies"):
- `Matrix.Movie.Play` stub delivers pre-recorded bytes
- `Matrix.Backend.Test` captures them in-memory
- ExUnit spec calls `Elui.Backend.Test.to_lines(backend_state)` → list of screen strings
- Assert against expected output

When recording (`TAPE=rec`):
- Live run with `Matrix.Backend.Ansi` (real terminal)
- `Matrix.Movie.Store` collects bytes via `record_bytes/1`
- On app exit, serialize to cassette "movies" key
- Cost: ~$0.01 (one real Claude call)

---

## SECOND ORDER (noted for later): El's Own UI

**Scope:** El itself (the CLI) will have an Elui.App face. Today el is a bare REPL with Matrix wrapping Claude. Tomorrow:

```
el
├─ Elui.App
│  ├─ Render: help/status/agent list
│  └─ Input: keyboard (↑↓ to nav, enter to select agent)
└─ Matrix.Pty.App (when user selects "claude")
   └─ Claude in a PTY (full ANSI screen)
```

This is a structural echo: Elui.App at the top level, Matrix.Pty.App (also Elui.App) as a child. Navigation sits in outer loop; claude's screen sits in inner.

**Deferred:** Full design after this phase lands.

---

## Current Matrix Architecture (what stays, what dies)

### Matrix.Pty (GenServer) — STAYS with wrapping
- `boot(name, cmd, opts)` — spawns Claude
- `inject(name, msg)` — send input to stdin
- `watch(name, pid)` — tap output
- `launch/join` — full lifecycle

**Will be refactored to:**
- Separate concerns: spawning (stays), I/O multiplexing (moves to Elui backend), raw mode (moves to Elui.Input)

### Spawning Claude in a PTY — STAYS, same seam
```
Matrix.Pty.Boot.launch(port, cmd, size)
  → /usr/bin/script + stty raw -echo -isig
  → spawns: claude --dangerously-skip-permissions
  → returns: pty handle (Port or Matrix.Movie.Play stub)
```

**Stays because:** we need full control over the Claude subprocess (signals, I/O relay). The seam is the `port` module we pass in.

### Byte-level logging — STAYS, already exists
`Matrix.Trace.record(data)` logs all I/O to session logs. This is orthogonal to taping.

### What dies:
- **Hand-rolled stty calls** — Elui.Input manages it
- **Matrix.Pty.Gate + Matrix.Pty.Buffer** — Elui.Buffer.Test captures state cleanly
- **Matrix.Pty.Dsr (DSR protocol hack)** — Elui.Terminal.autoresize() handles resize events
- **Matrix.Pty.Watch tail-f polling** — Elui's event loop (no file polling)
- **Matrix.Pty.Dispatch byte-to-screen translation** — Elui.Backend does this

---

## The Tape Seam: Backend Selection at Boot

**Today (donny lane precedent):**
```elixir
# Matrix.Pty.Config.pick/2
defp pick(nil, opts) do
  choose(replaying?(), exists?(opts[:name]))
end

defp choose(true, true), do: Matrix.Movie.Play  # replay mode + cassette has reel
defp choose(_, _), do: Port                      # real Erlang port
```

**Tomorrow (with Elui):**
Same pattern, but for backends:
```elixir
# Matrix.Pty.Config.pick/2 (NEW)
defp pick(nil, opts) do
  choose(replaying?(), exists?(opts[:name]))
end

defp choose(true, true), do: Elui.Backend.Test   # replay: in-memory capture
defp choose(_, _), do: Elui.Backend.Ansi         # live: real terminal
```

The backend is passed to `Elui.Terminal.new(backend: backend_mod)`.

---

## Module Map: What Elui Replaces

| Matrix layer | Current impl | Elui replacement | Notes |
|---|---|---|---|
| **Raw mode** | `stty raw -echo -isig` (shell-outs in Matrix.Pty.Init) | `Elui.Input.enable_raw_mode()` | Exact stty save/restore |
| **Screen buffer** | Matrix.Pty.Buffer (hand-rolled ansi parsing) | Elui.Buffer.Test (in-memory Cell grid) | Double-buffered, diff'ed |
| **Terminal I/O** | `IO.write(out, data)` + Port.command | Elui.Backend.Ansi (ANSI escapes) | Same output, cleaner API |
| **Resize events** | DSR protocol hack (Matrix.Pty.Dsr) | `Elui.Terminal.autoresize()` + `:resize` event | Polled vs event-driven |
| **Input events** | Raw bytes → manual key parsing | Elui.Input (full ESC/CSI parser) | Reuse, much cleaner |
| **Event loop** | Matrix.Pty.Dispatch.info/2 matches on port messages | Elui.App event loop (or manual Terminal.draw + loop) | Already sketched in Elui.App |

---

## Three Seams Where Things Connect

### 1. Spawning Claude (INVARIANT)
```elixir
# stays the same
Matrix.Pty.Boot.launch(port_module, cmd, size)
  |> port_module.open({:spawn_executable, "/usr/bin/script"}, opts)
```

When replaying: `port_module = Matrix.Movie.Play`
When live: `port_module = Port`

### 2. Raw Mode (MOVES)
```elixir
# BEFORE (Matrix.Pty.Init + Matrix.Pty.Env + hand-rolled stty)
setup(cfg[:file], pty, size) do
  file.open("/dev/tty", [:read, :binary, :raw])
  |> mirror(file, size)
  |> pump(file)
end

# AFTER (Elui.Input)
input_session = Elui.Input.start(subscriber: self(), mouse: false)
# exact stty -g save/restore inside
# delivers {:elui_event, {:key, ...}} to subscriber
```

Replace `Matrix.Pty.Init.pump/pump_read/pump_terminal` with Elui.Input async reader.

### 3. Screen Buffer & Backend Selection (CRITICAL)
```elixir
# NEW: Matrix.Pty.Terminal wrapper (thin layer)
defmodule Matrix.Pty.Terminal do
  def init(opts) do
    backend = opts[:backend] || Elui.Backend.Ansi
    terminal = Elui.Terminal.new(backend: backend)
    {:ok, %{terminal: terminal, buffer: []}}
  end

  def draw(state, data) do
    # parse ANSI from claude, update cells in terminal
    # backend.draw([{x, y, cell}, ...])
  end

  def state(pstate), do: Elui.Terminal.backend_state(pstate.terminal)
end
```

When replaying: `Elui.Backend.Test` → `Elui.Backend.Test.to_lines()` → compare in spec
When live: `Elui.Backend.Ansi` → `IO.write()` to real terminal

---

## Door Spec: Smallest POC ($0 replay-only proof)

**File:** `apps/specs/test/door_test.exs` (ExUnit, not cukes)

**Flow:**
1. `TAPE=replay` mode checks: cassette has "movies" key?
2. If yes: `Matrix.Movie.Play` stub + `Matrix.Backend.Test` in-memory buffer
3. App loops: stub delivers byte chunks → Ansi.feed → backend.draw → assert screen
4. Zero cost: no live Claude call, pure replay

**What it does:**
```elixir
test "first trip: see welcome, math works" do
  # Boot Matrix.Pty.App with replaying mode
  {:ok, pid} = Matrix.Pty.App.run(:malko, [
    cmd: "claude --dangerously-skip-permissions",
    get_size: fn -> {24, 80} end,
    name: :malko,
    backend: Matrix.Backend.Test,  # in-memory capture
    port: Matrix.Movie.Play         # replay stub (auto-selected by config)
  ])
  
  # App loop happens; movie delivers bytes, parser runs, screen captured
  # Send input: would flow through pty (but pty is a stub in replay mode)
  # Simulate: Matrix.Movie.Play ignores command/2, so no actual write needed
  
  # Query captured screen
  screen = Matrix.Backend.Test.to_lines()  # from Agent:Elui.Backend.Test
  text = Enum.join(screen, "\n")
  
  assert text =~ "Welcome"
  assert text =~ "2"
end
```

**Key file paths:**
- `features/cassettes/door.json` → add `"movies": [<byte chunks>]` key (one live recording)
- `apps/specs/test/door_test.exs` → NEW ExUnit spec
- `apps/matrix/lib/matrix/pty/app.ex` → NEW Elui.App (replaces GenServer Pty)
- `apps/matrix/lib/matrix/ansi.ex` → NEW ANSI parser (~200 lines)
- `apps/matrix/lib/matrix/backend/ansi.ex` → NEW wrapper
- `apps/matrix/lib/matrix/backend/test.ex` → NEW wrapper + byte capture
- `apps/matrix/lib/matrix/movie/play.ex` → copy from donny
- `apps/matrix/lib/matrix/movie/load.ex` → copy from donny
- `apps/matrix/lib/matrix/movie/store.ex` → NEW agent for taping

**Updated POC slices (kenny-sized, one per PR):**

1. **Add Elui to matrix mix.exs + copy Matrix.Movie.Play/Load from donny**
   - Outcome: Matrix can boot with `port: Matrix.Movie.Play` (passes config gate)

2. **Write Matrix.Ansi parser** (~200 lines, handle direct chars + CSI)
   - Outcome: feed bytes, get back updates list `[{x, y, cell}]`
   - Coverage: write_char, carriage_return, newline, clear, cursor moves (A/B/C/D/H)

3. **Create Matrix.Backend.Ansi/Test wrappers** (~80 lines total)
   - Outcome: config.pick returns backend module, Elui.Terminal.new uses it
   - Coverage: both init/draw/restore (others forward)

4. **Write Matrix.Pty.App** (Elui.App, ~150 lines)
   - Outcome: boots PTY, owns Terminal, routes events, shows ansi.buffer in view
   - Coverage: init (spawn PTY + create Terminal), update (key/resize/pty_data), view

5. **Wire El.Commands.Claude → Matrix.Pty.App.run**
   - Outcome: `el claude malko` still works live (no breakage)
   - Test: run interactively, see welcome, type `1 + 1`, see answer, `/exit` clean

6. **Record one live door cassette** (`TAPE=rec CASSETTE=door`)
   - Outcome: cassette gains "movies" key with byte chunks
   - Cost: ~$0.01

7. **Write door_test.exs** (~30 lines)
   - Outcome: `mix test apps/specs/test/door_test.exs` passes at $0
   - Assertion: screen contains "Welcome" + "2"

**Why this order:**
- Slices 1-3 are setup (enable config.pick, parse, render)
- Slice 4 is integration (app loop + event dispatch)
- Slice 5 is compatibility (el still works today)
- Slice 6 is the gate: one live call to fill cassette
- Slice 7 proves the replay works

No cukes changes yet. Door.feature stays @live. ExUnit proves the flow.

---

## Stitching: How El.Commands.Claude evolves (near-invisible)

**Today:**
```elixir
def claude(name) do
  pid = Matrix.Pty.launch(name, opts(buf, cmd))
  Matrix.Pty.join(pid)
end
```

**Tomorrow:**
```elixir
def claude(name) do
  # Matrix.Pty.App.run is Elui.App.run with model/update/view
  # Blocks until :quit event
  # No visible change to caller
  Matrix.Pty.App.run(name, opts(buf, cmd))
end
```

**Background:** Matrix.Pty.Config.pick/2 inspects TAPE env and cassette key. If replaying, selects Matrix.Backend.Test automatically. Caller doesn't know or care. Same subprocess, same Claude output, different rendering path.

---

## Design Rules & Seam Preservation

1. **Matrix.Pty becomes an Elui.App, not a GenServer.**
   - Old: Pty.Dispatch.info/2 dispatches port messages
   - New: Pty.App.update/2 dispatches all events (key, resize, pty_data, tick)
   - No middle ground: all event routing is declarative, no tail recursion in dispatch

2. **Matrix.Ansi is the ANSI→Cell parser, period.**
   - It's handmade VT100, not a full terminal emulator
   - Scope: exactly what Claude emits (printable + \r\n\t + CSI A/B/C/D/H/2J/K)
   - Stateful but pure: `feed(bytes)` returns new state, no side effects
   - Never holds port references or backend state

3. **Backend selection is ONE seam: Matrix.Pty.Config.pick/2**
   - Replay check: `replaying?() && exists?(name)` → Matrix.Backend.Test
   - Live: → Matrix.Backend.Ansi
   - No replay logic in app loop, dispatch, or renderer

4. **Watcher Task replaces Matrix.Pty.Init pump.**
   - Old: start/2 spawned a reader process that pumped stdin tty
   - New: start a Task that reads PTY in a loop, sends {:message, {:pty_data, bytes}}
   - Same async architecture, cleaner event flow

5. **Cukes stay unchanged; ExUnit proves replay.**
   - Cukes: `@live`, drive `el` commands, interactive
   - ExUnit: `@tag :replay`, proof that $0 gate works
   - No cuke changes until we're confident in replacements

6. **Money: one recording gate, forever $0.**
   - `TAPE=rec CASSETTE=door el claude malko` → one live Claude call (~$0.01)
   - Cassette "movies" key stored
   - All future runs: `TAPE=replay` → $0, use stored bytes

7. **Stitching El.Commands.Claude: minimal**
   - Delete: Matrix.Pty.launch + Matrix.Pty.join
   - Add: Matrix.Pty.App.run (no signature change needed if we hide impl details)
   - Caller doesn't care: it still boots Claude and waits

---

## Open Questions for Boss

1. **Cuke-vs-ExUnit split:**
   - Cukes stay `@live`, test full CLI and e2e flows (el commands, agent discovery, etc.)
   - ExUnit tests isolated layers (parser, app logic, backend capture)
   - Door.feature stays as-is; door_test.exs is new proof
   - **Resolved in design above:** both run, ExUnit proves replay works at $0, cukes verify CLI

2. **Scroll behavior in Matrix.Ansi:**
   - Ruby screen.rb scrolls on overflow; should Matrix.Ansi?
   - Current design: `scroll_up` just wraps cursor (conservative)
   - **Question:** Do we need real scroll (shift lines up) or is cursor wrap enough?
   - **Proposal:** Start with wrap; if tests fail, add shift

3. **Resize mid-session:**
   - When outer terminal resizes, Elui.Terminal detects it and emits `:resize` event
   - Matrix.Pty.App signals PTY with SIGWINCH and rebuilds parser
   - **Question:** Does this clear the screen or preserve it?
   - **Proposal:** Clear (conservative). Real terminals do this anyway.

4. **Keyboard encoding:**
   - Elui.Input delivers `:key` events; we need to encode them as bytes for PTY
   - How do we handle modifiers (ctrl+c, alt+x, etc.)?
   - **Proposal:** Use a key_to_bytes function; ctrl+c = 0x03, printables as UTF-8, etc.

5. **Backward compat: `el claude` live mode:**
   - Must work today without breaking
   - Proposed solution: Elui.Backend.Ansi renders to stdout, Elui.Input reads from stdin
   - Test: run `el claude` interactively, see welcome, math works, /exit clean
   - **Blocker:** Do we need to preserve the hand-rolled stty setup, or does Elui.Input.enable_raw_mode suffice?
   - **Proposal:** Use Elui.Input; if it fails, fall back to hand-rolled

6. **Taps (watchers):**
   - Today: Matrix.Pty.watch(name, pid) registers watchers, Dispatch notifies them
   - New: Matrix.Pty.App has taps list; forward bytes in update loop
   - **Question:** Do we preserve the tap interface or move to event subscription?
   - **Proposal:** Keep the interface; impl simplifies to: `notify_taps(taps, bytes)`

---

## File Checklist for POC (7 slices, 1 per PR)

**Slice 1: Setup + Stubs**
- [ ] `apps/matrix/mix.exs` — add `{:elui, path: "../../ext/elui"}`
- [ ] `apps/matrix/lib/matrix/movie/play.ex` — copy from donny
- [ ] `apps/matrix/lib/matrix/movie/load.ex` — copy from donny
- [ ] `apps/matrix/lib/matrix/movie/store.ex` — NEW simple agent

**Slice 2: Parser**
- [ ] `apps/matrix/lib/matrix/ansi.ex` — NEW ANSI→Cell parser (~200 lines)
  - `init/2`, `feed/2`, `process_char/2`, `dispatch_escape/2`
  - Handle: direct chars, `\r\n\t`, CSI (A/B/C/D/H/2J/K)

**Slice 3: Backends**
- [ ] `apps/matrix/lib/matrix/backend/ansi.ex` — NEW wrapper (~30 lines)
- [ ] `apps/matrix/lib/matrix/backend/test.ex` — NEW wrapper + capture (~50 lines)

**Slice 4: App Loop**
- [ ] `apps/matrix/lib/matrix/pty/app.ex` — NEW Elui.App (~150 lines)
  - `init/1`: spawn PTY, create Terminal, start Elui.Input
  - `update/2`: dispatch on event type
  - `view/2`: render Ansi.buffer to frame

**Slice 5: Integration**
- [ ] `apps/matrix/lib/matrix/pty/config.ex` — edit pick/2 to return backend mod
- [ ] `apps/el/lib/el/commands/claude.ex` — use Matrix.Pty.App.run instead of Matrix.Pty.launch

**Slice 6: Record**
- [ ] `features/cassettes/door.json` — manual run: `TAPE=rec CASSETTE=door el claude malko`

**Slice 7: Test**
- [ ] `apps/specs/test/door_test.exs` — NEW ExUnit spec (~30 lines)

---

## Success Criteria (per slice)

**Slice 1:**
- [ ] `mix compile` green, no deps conflicts

**Slice 2:**
- [ ] `Matrix.Ansi.feed(ansi, bytes)` returns state with populated `updates` list
- [ ] Gates: simple char write, carriage return, newline, all CSI types
- [ ] `mix test` (new spec file exists and tests parser in isolation)

**Slice 3:**
- [ ] `Matrix.Backend.Ansi.init([])` returns Elui.Backend.Ansi state
- [ ] `Matrix.Backend.Test.init([])` returns Elui.Backend.Test state
- [ ] Both forward all 8 Elui.Backend callbacks

**Slice 4:**
- [ ] `Matrix.Pty.App.run(:malko, opts)` boots, model has terminal+ansi+pty
- [ ] `update/2` routes events (key, resize, pty_data)
- [ ] `view/2` renders frame, no errors
- [ ] `mix test` gates green

**Slice 5:**
- [ ] `mix compile` green
- [ ] `el claude` launches, sees welcome message
- [ ] Type `1 + 1`, see `2` (no assertion, manual check)
- [ ] `/exit` cleanly shuts down

**Slice 6:**
- [ ] Run: `TAPE=rec CASSETTE=door el claude malko`, then `1 + 1`, then `/exit`
- [ ] Cassette gained "movies" key with byte array
- [ ] **Cost logged:** ~$0.01

**Slice 7:**
- [ ] `mix test apps/specs/test/door_test.exs` passes at $0 (TAPE=replay mode)
- [ ] Screen assertions: text contains "Welcome", "2"
- [ ] No live calls made (proof: TAPE=replay works)

**Overall:**
- [ ] No breaking changes to El.Commands.Claude from caller's view
- [ ] Live mode (`el claude`) unchanged and works
- [ ] Cukes still pass (unchanged)
- [ ] One clear seam: Matrix.Pty.Config.pick/2 selects backend (no replay logic scattered)
