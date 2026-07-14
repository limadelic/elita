# Wrapped Claude → El CLI Path (#9)

## Problem Statement
When a wrapped claude (running inside el REPL) invokes `el tell foo bar`, it spawns a NEW OS process running the el escript. This new process tries to start its own Erlang node distribution, causing a **collision** with the parent el's node because both attempt to register the same node name with the Erlang Port Mapper Daemon (epmd).

## Current Wiring

### PATH Prepend (wrapped process isolation)
**File:** `/Users/mike/dev/self/elita/malko/features/support/spawn.rb:42`
```ruby
env["PATH"] = [(@scratch ? "#{@scratch}/bin" : nil), ENV["PATH"]].compact.join(":")
```
When @scratch is set (for @malko tag), PATH includes the scratch bin directory first.

### Escript Symlink (el executable)
**File:** `/Users/mike/dev/self/elita/malko/features/support/stub.rb:13-15`
```ruby
el_escript = File.expand_path('../../apps/el/el', __dir__)
el_link = File.join(bin_dir, 'el')
File.symlink(el_escript, el_link) unless File.exist?(el_link)
```
A symlink to the real el escript is placed in the scratch bin directory.

### Escript Entry Point
**File:** `/Users/mike/dev/self/elita/malko/apps/el/mix.exs:12`
```elixir
escript: [main_module: El.CLI, emu_args: ""]
```
El.CLI.main/1 is the escript entry point with no custom emulator args.

### Distribution Startup
**File:** `/Users/mike/dev/self/elita/malko/apps/el/lib/el/boot.ex:12-15, 23-24`
```elixir
def start(name \\ :default, opts \\ []) do
  :os.cmd(~c"epmd -daemon")
  boot(node(name, opts), mode(opts))
end

defp node(:default, opts), do: :"#{cwd!() |> basename()}@#{get(opts, :host, host())}"
defp node(name, opts), do: :"#{name}@#{get(opts, :host, host())}"
```
- Starts epmd (Erlang Port Mapper Daemon) if not running
- Computes node name from current working directory's basename
- With default name, node becomes `elita@127.0.0.1` (since cwd is `apps/elita/agents/elita`)

### Distribution Start Called
**File:** `/Users/mike/dev/self/elita/malko/apps/el/lib/el/cli.ex:29-31`
```elixir
def main(argv) do
  ensure_all_started(:elita)
  argv |> route() |> exec()
end
```
El.CLI.main calls ensure_all_started(:elita), which eventually calls El.Distribution.start/0

**File:** `/Users/mike/dev/self/elita/malko/apps/el/lib/el/commands/tell.ex:12-16`
```elixir
def tell(agent, msg, tool \\ nil, opts \\ []) do
  start()
  ...
end
```
Both `tell` and `ask` commands call El.Distribution.start() before routing.

## The Nesting/Collision Problem

### Scenario Flow
1. **Parent Process**: Test harness spawns `el claude malko` (starts malko session with stub REPL)
2. **Wrapped Claude**: Inside the malko stub, simulates claude typing `malko> tell malkovich "hello"`
3. **New OS Process**: The malko stub script invokes:
   ```bash
   cd apps/elita/agents/elita && \
   TAPE=replay CASSETTE=malkovich CASSETTE_DIR=... MIX_ENV=test \
   /path/to/el tell malkovich "hello"
   ```
4. **Erlang Boot Collision**: 
   - New el escript process calls El.Boot.start/1
   - Computes node name from cwd: `basename("apps/elita/agents/elita")` = `"elita"`
   - Tries to register node `elita@127.0.0.1` with epmd
   - **COLLISION**: epmd already has `elita@127.0.0.1` registered by parent el process
   - Error: port mapper could not connect to local node or similar

### Why It's a Problem
- Parent and wrapped el are **separate OS processes** with separate Erlang runtimes
- They share the same **epmd** (port mapper daemon, machine-wide)
- Both try to claim the same **node name** based on working directory
- The wrapped el has no way to know about the parent el's node
- No handshake exists to redirect wrapped el commands to parent el

## Solution Options

### Option A: Erlang Hidden Node + Environment Handshake (RECOMMENDED)
**Mechanism**: Parent el sets `EL_NODE=elita@127.0.0.1` env var. Wrapped el detects it and:
1. Starts with unique node name (e.g., `elita_wrapped_<pid>@127.0.0.1`)
2. Passes `hidden: true` to `Node.start/2` (doesn't register with epmd for local discovery)
3. Connects to parent node via `Node.connect(:"elita@127.0.0.1")`
4. Routes all tell/ask commands through parent's global registry

**Pros:**
- Minimal infrastructure: just an env var check
- Leverages existing global registry mechanism (ask/tell already use `:global.register_name`)
- Hidden nodes don't collide with epmd port mapping
- Works within current distributed Erlang architecture
- Wrapped el keeps full node capability (logging, monitoring) but delegates command routing

**Cons:**
- Still spins up full Erlang runtime per wrapped invocation
- Cookie handshake must match between parent and wrapped

**Files to touch:**
- `apps/el/lib/el/boot.ex`: Check EL_NODE env, choose hidden node + connect logic
- `apps/el/lib/el/commands/tell.ex` & `ask.ex`: Detect hidden node, route to parent

### Option B: Unix Socket IPC to Parent Daemon
**Mechanism**: Parent el listens on `/tmp/elita_<hostname>.sock`. Wrapped el:
1. Detects parent via socket file or env var
2. Sends JSON-RPC request to parent daemon instead of starting own runtime
3. Receives routed response

**Pros:**
- No Erlang distribution needed in wrapped process
- Lightest weight
- Clean client-server separation

**Cons:**
- Requires new IPC protocol (JSON-RPC or msgpack)
- Parent must run in daemon mode to be reachable
- More infrastructure change; existing code assumes Erlang distribution

### Option C: Separate Epmd per Scratch Dir
**Mechanism**: Start custom epmd for each test run on different port

**Pros:**
- No connection needed between parent and wrapped

**Cons:**
- Fragile, breaks tell/ask across nodes anyway
- Port collision risk across concurrent tests
- Doesn't align with architecture (ask/tell should work within same cluster)

## Recommendation: Option A (Hidden Node + EL_NODE)

**Rationale:**
1. Minimal change to existing codebase
2. Leverages distributed Erlang's hidden node feature (designed for this)
3. Reuses ask/tell's global registry; no new protocol
4. Single env var handshake: parent sets, wrapped checks
5. Testable in isolation (set env var, call wrapped el, verify connect)
6. Failure mode is graceful: if EL_NODE not set, wrapped el starts standalone (existing behavior)

**Implementation sketch:**
```elixir
# El.Boot.start/2: check for parent node
defp boot(name, mode) when is_parent_node() do
  :os.cmd(~c"epmd -daemon")
  unique_name = random_node_name()  # e.g., elita_<random>@host
  connect_to_parent(unique_name, mode)  # start hidden, connect
end

defp connect_to_parent(name, mode) do
  fn -> Node.start(name, mode, hidden: true) end
  |> then(&attempt/3)
  |> then(&connect_parent/1)
end

defp is_parent_node do
  System.get_env("EL_NODE") != nil
end
```

## Smallest Testable Slice

### Feature: `malko/wrapped_el.feature`
```gherkin
@malko @wip
Feature: Wrapped claude invokes el tell/ask
  
  Scenario: Tell from wrapped process reaches other session
    * > el claude malkovich
      | Claude Code |
    * > el claude malko
      | Claude Code |
    * malko> tell malkovich hello from wrapped
    * malkovich:
      | from malko |
      | hello from wrapped |
    * malko> /exit
    * malkovich> /exit
```

**What it asserts:**
1. Wrapped el (running inside malko stub) successfully invokes `tell`
2. Message routes to malkovich's global process
3. No "port mapper" or "already started" errors in logs
4. Bidirectional communication works (malkovich can reply via tell back to malko)

### Test setup changes needed:
- `spawn.rb:42` (launch): Set `EL_NODE=elita@127.0.0.1` in env when @malko tag
- Or detect from first el invocation and propagate to wrapped invocations

## Files Involved (No Changes Yet)

**Read-only references:**
- `/Users/mike/dev/self/elita/malko/apps/el/lib/el/boot.ex` — node naming, epmd, Node.start
- `/Users/mike/dev/self/elita/malko/apps/el/lib/el/cli.ex` — ensure_all_started entry
- `/Users/mike/dev/self/elita/malko/apps/el/lib/el/commands/tell.ex` — start() call, global registry
- `/Users/mike/dev/self/elita/malko/apps/el/lib/el/commands/ask.ex` — start() call
- `/Users/mike/dev/self/elita/malko/apps/el/lib/el/distribution.ex` — start/0, connect, daemon
- `/Users/mike/dev/self/elita/malko/features/support/spawn.rb` — PATH, env setup
- `/Users/mike/dev/self/elita/malko/features/support/stub.rb` — symlink creation
