# LAN Distribution Plan (#9-13)

## 1. Current State

### Node Names & Host Configuration
- **Default host**: `127.0.0.1` (hardcoded fallback)
- **Host source**: `EL_HOST` env var → `El.Host.host()` → `El.Boot.start()` (apps/el/lib/el/boot.ex:23)
- **Node atom construction**: `:"#{name}@#{host}"` (boot.ex:23-24)
- **Mode selection**: `El.Boot.mode()` reads host, if contains "." → `:longnames`, else `:shortnames` (boot.ex:17-20)

### Hardcoded Host References
All currently hardcoded to `127.0.0.1`:
- `El.Distribution.target/1` (apps/el/lib/el/distribution.ex:32) — connect to `:"#{name}@127.0.0.1"`
- `El.Distribution.daemon/0` (apps/el/lib/el/distribution.ex:61) — `Node.start(:"elita@127.0.0.1", :longnames)`
- `El.Distribution.Helpers.attach/1` (apps/el/lib/el/distribution/helpers.ex:21) — connect to `:"#{name}@127.0.0.1"`
- `El.Distribution.Helpers.locate/1` (apps/el/lib/el/distribution/helpers.ex:26) — node atom `:"#{name}@127.0.0.1"`
- `El.Command.Ls.Query` (apps/el/lib/el/command/ls/query.ex:8-9) — connect/call to `:"elita@127.0.0.1"`
- `Elita.Chat` (apps/elita/lib/utils/chat.ex) — start `:"#{name}@127.0.0.1"`

### Cookie Management
- **Cookie**: hardcoded to `:elita` (apps/el/lib/el/boot.ex:60)
- `Node.set_cookie(:elita)` called after node start
- No env var support
- No ~/.erlang.cookie fallback

### epmd & Port Configuration
- epmd started in daemon mode: `:os.cmd(~c"epmd -daemon")` (apps/el/lib/el/boot.ex:13)
- Default epmd port: `4369` (Erlang standard, not configurable currently)
- inet_dist ports: **NOT configured** — defaults to OS ephemeral range (20000-32767 typically)
- No firewall-friendly port pinning

### Distribution Discovery
- Local registry: `ElitaRegistry` (Registry pattern, :unique key)
- Global registry: `:global.register_name({name, :puppet}, pid)` when `Node.alive?()` (puppet.ex:37)
- Peer tracking: `El.Peers.load()` reads `~/.elita/peers` (apps/el/lib/el/peers.ex)
- Dial-on-startup: `El.Distribution.Helpers.dial()` → loads peers, connects to each (distribution/helpers.ex:14-18)

---

## 2. Changes for Longnames (Cross-Machine)

**Architecture shift**: Node names must include FQDN or IP, not just shortnames.

### Required Changes

1. **Remove 127.0.0.1 hardcodes**, use EL_HOST throughout:
   - `El.Distribution.target/1`: Use `El.Host.host(opts)` instead of `"127.0.0.1"`
   - `El.Distribution.daemon/0`: Read host from opts/env, construct node dynamically
   - `El.Distribution.Helpers.attach/1` & `locate/1`: Pass host param or fetch from env
   - `El.Command.Ls.Query`: Accept host parameter or read env
   - `Elita.Chat`: Accept host parameter

2. **Longnames mode always when host contains "." or is FQDN**:
   - Already in `El.Boot.mode()` — verify mode is `:longnames` for any cross-machine node
   - On single machine, can use `:shortnames` if host is bare hostname or localhost

3. **CLI/API**: Allow specifying remote host:
   - `el ask user@hostname.local message`
   - `el tell agent@192.168.1.10 message`
   - New pattern: `el -H hostname ask agent message` (or env var approach)

---

## 3. Cookie Sharing Approach

**Decision: Environment variable + ~/.erlang.cookie fallback**

### Implementation

1. **Priority order** (highest to lowest):
   - `EL_COOKIE` env var (per ~/.zshrc)
   - `~/.erlang.cookie` if it exists (standard Erlang convention)
   - Hardcoded default `:elita` (current behavior)

2. **Code change** (apps/el/lib/el/boot.ex):
   ```elixir
   defp cookie(val) do
     cookie_name = read_cookie() |> to_atom()
     set_cookie(cookie_name)
     val
   end

   defp read_cookie do
     get_env("EL_COOKIE") || read_erlang_cookie() || "elita"
   end

   defp read_erlang_cookie do
     path = Path.join(System.user_home!(), ".erlang.cookie")
     if File.exists?(path) do
       File.read!(path) |> String.trim()
     end
   rescue
     _ -> nil
   end
   ```

3. **User setup** (in ~/.zshrc):
   ```bash
   export EL_COOKIE=my_shared_cookie
   ```

---

## 4. inet_dist Port Pinning for Firewalls

**Goal**: Allow two machines to communicate through fixed port range instead of ephemeral.

### Configuration Method

Set in vm.args or via sys.config **at node startup**:
```erlang
-kernel inet_dist_listen_min 9100
-kernel inet_dist_listen_max 9110
```

Alternatively, via environment or sys.config:
```elixir
# In config.exs or at boot time
Application.put_env(:kernel, :inet_dist_listen_min, 9100)
Application.put_env(:kernel, :inet_dist_listen_max, 9110)
```

### Implementation Location

- Add to `El.Boot.start/2` **before** `Node.start()`:
  ```elixir
  defp boot(name, mode) do
    configure_inet_dist()
    fn -> Node.start(name, mode) end
    |> then(&attempt(&1.(), &1, 5))
    |> act(name, mode)
  end

  defp configure_inet_dist do
    min = get_env("EL_INET_DIST_MIN", "9100") |> String.to_integer()
    max = get_env("EL_INET_DIST_MAX", "9110") |> String.to_integer()
    Application.put_env(:kernel, :inet_dist_listen_min, min)
    Application.put_env(:kernel, :inet_dist_listen_max, max)
  end
  ```

### Firewall Setup Example (2-machine LAN)
```
Firewall rules:
- Allow TCP 4369 (epmd) between machines
- Allow TCP 9100-9110 (inet_dist) between machines
- Allow TCP 22 (ssh) for initial connection (optional)
```

---

## 5. Smallest Testable Slice: "BANANA Crosses the LAN"

**Scope**: Two machines, same LAN, ask/tell handshake.

### Feature Scenario (features/malko/lan.feature)
```gherkin
@malko @lan
Feature: LAN Distribution

  Scenario: BANANA crosses LAN
    * > el -H banana.local claude claude_peer
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el -H peeler.local claude peeler
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * peeler> ask claude_peer knock knock
    * peeler:
      | who's there |
```

### Test Flow
1. Start two Claude agents on different machines (or simulated via containers):
   - Machine "banana.local" — agent `claude_peer`
   - Machine "peeler.local" — agent `peeler`
2. From `peeler`, ask `claude_peer@banana.local` a knock-knock joke
3. `banana` responds, message routed via `:global.register_name` across nodes
4. `peeler` receives response

### Assertions
- Both nodes report `Node.alive?() == true`
- `:global.sync()` completes without timeout
- Message survives network round-trip (ask → invoke → reply)
- No stale cookies or connection failures

---

## 6. Risks & Mitigations

### Risk: Shared epmd on One Box vs Two Boxes
**Problem**: If two Erlang systems run on the same machine with different node names, they can share one epmd (port 4369). Across machines, each box runs its own epmd.

**Impact**:
- Same machine (current tests): One epmd, multiple nodes register locally
- Cross-machine: Two epmd processes (one per box), nodes discover via network epmd lookup

**Mitigation**:
- Ensure epmd is running in daemon mode (already done: `:os.cmd(~c"epmd -daemon")`)
- Test suite must not assume same machine — use `-H hostname` flag or mock network
- In CI, spawn fresh containers or VMs to avoid epmd collision

### Risk: Node Name Collisions
**Problem**: If two machines try to start with same node name (e.g., both `malko@banana.local`), only first wins.

**Impact**: RPC calls route to wrong node; ask/tell fails silently.

**Mitigation**:
- Enforce unique node names per machine (include machine name in node atom)
- Document: `el claude malko` on banana.local creates `malko@banana.local`, not `malko@127.0.0.1`
- CI: Generate unique machine names (e.g., `malko_${MACHINE_ID}@host`)

### Risk: Cookie Mismatch Across Machines
**Problem**: If machines have different `EL_COOKIE` values, nodes refuse to connect.

**Impact**: `:global.register_name` silently fails; `ask`/`tell` hangs or times out.

**Mitigation**:
- Store shared cookie in `~/.elita/cookie` (created on first LAN setup)
- Document: "All machines on LAN must have same `EL_COOKIE` or `~/.erlang.cookie`"
- Test: Verify cookie before attempting cross-machine ask (add pre-flight check)

### Risk: Firewall Blocking inet_dist Ports
**Problem**: Default ephemeral port range (20000+) varies; firewall doesn't know which ports to open.

**Impact**: Two machines can't establish inet_dist connections; ask/tell hangs.

**Mitigation**:
- Require `EL_INET_DIST_MIN`/`EL_INET_DIST_MAX` env vars for cross-machine tests
- Default to safe range (9100-9110) if running on non-127.0.0.1 host
- CI setup: Document firewall rules (see section 4 example)

### Risk: DNS/Hostname Resolution Delays
**Problem**: FQDNs (e.g., `banana.local`) may take time to resolve; ask/tell timeout.

**Impact**: Intermittent failures in tests; confusing timing bugs.

**Mitigation**:
- Use IP addresses in tests (more reliable than mDNS)
- Add DNS cache warmup in `El.Distribution.wait/1` (resolve hostname once at boot)
- Increase ask timeout from 5s default to 10s for cross-machine (configurable)

### Risk: Tape Replay Breaks Cross-Machine Tests
**Problem**: Cassettes recorded on one machine may reference node names (`malko@127.0.0.1`) that don't exist on another.

**Impact**: $0 replay fails; must re-record for each machine config.

**Mitigation**:
- Cassettes should normalize node names (strip host, use atom only: `:malko`)
- Or: Record with IP address, replay with hostname — tape replay lib must abstract hostname
- For now: LAN tests must `TAPE=rec` once per machine setup (not $0 yet)

---

## 7. Implementation Order

1. **Phase 1: Host Parameterization** (lowest risk)
   - Remove 127.0.0.1 hardcodes; plumb `EL_HOST` through distribution module
   - Add `-H hostname` CLI flag or env var
   - Verify single-machine tests still pass

2. **Phase 2: Cookie Flexibility** (medium risk)
   - Implement `EL_COOKIE` env var + ~/.erlang.cookie fallback
   - Update test fixtures to set `EL_COOKIE` explicitly
   - Verify cookie is set before node start

3. **Phase 3: inet_dist Pinning** (medium risk)
   - Add `EL_INET_DIST_MIN/MAX` env vars to El.Boot
   - Default to safe range (9100-9110) when host != 127.0.0.1
   - Firewall documentation in CLAUDE.md

4. **Phase 4: LAN Feature & Tests** (high integration risk)
   - Add `features/malko/lan.feature` with knock-knock scenario
   - Spawn two agents on same machine (different node names) to simulate LAN
   - Tape: record live once per machine; replay with $0 (may require cassette normalization)
   - CI: Add LAN test job (separate from main suite per CLAUDE.local.md notes)

5. **Phase 5: Ask-on-Tell Inversion** (architectural)
   - After LAN is stable, revisit ask/tell semantics for cross-machine parity
   - Ensure tell bypasses ask, maintains fire-and-forget semantics across network

---

## File Locations

**Distribution core**:
- apps/el/lib/el/boot.ex (node start, mode, cookie)
- apps/el/lib/el/distribution.ex (target, bind, daemon)
- apps/el/lib/el/distribution/helpers.ex (attach, locate, dial)
- apps/el/lib/el/host.ex (host/mode resolution)

**CLI & commands**:
- apps/el/lib/el/cli.ex (argument parsing, -H flag)
- apps/el/lib/el/commands/ask.ex (routing via node name)
- apps/el/lib/el/commands/tell.ex (fire-and-forget routing)

**Tests**:
- features/malko/lan.feature (new)
- features/support/spawn.rb (PTY setup; may need -H propagation)
- features/support/hooks.rb (multi-agent spawn for LAN simulation)

**Configuration**:
- config/config.exs or apps/el/config/config.exs (inet_dist defaults)
- .claude/CLAUDE.md (document EL_HOST, EL_COOKIE, EL_INET_DIST_MIN/MAX)
