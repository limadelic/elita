# Cross-machine (work mac ↔ home mac)

Why: 9-5 needs to offload work from the work mac to the home mac via el, today.
Two macs stacked on one desk, same LAN. This is also elita's unshipped
distribution story (thesis: "unclaimed OTP territory") — el proves it first,
elita inherits the organs later.

## Shipped (el repo, wip branch, 2026-07-04)

- EL_HOST env: daemon binds a reachable host (default 127.0.0.1, unchanged behavior)
- EL_NODE env: CLI targets a remote daemon (e.g. el@home.local); unset = local as before
- naming mode auto: dots in host → longnames, no dots → shortnames
- EL_NODE set + remote unreachable → clear error, never spawns a rogue local daemon
- 488 tests green, lint clean, zero warnings; kenny built, cartman reviewed twice

## Mike's smoke test (blocks closing this)

1. same ~/.erlang.cookie on both macs
2. home: EL_HOST=home.local el --daemon
3. work: EL_NODE=el@home.local el start foo → send a message, confirm reply
4. merge the wip PR

## Next slices (in order, each shippable alone)

1. Ergonomics: stop typing env vars — el config file or `el --node home` alias
   mapping short names to node@host
2. Cross-daemon routing: @target> syntax reaching sessions on the other machine's
   daemon, not just the one you're attached to
3. Task handoff policy: which machine runs what — constraints are auth (ent login
   vs pro vs api token), quota left, machine load. Per thesis this is a PROGRAM
   (boss agent in markdown), not engine code; engine only exposes the facts
4. Shared visibility: see both daemons' sessions/logs from either CLI
   (MessageStore is DETS-local today; read-through rpc before inventing storage)

## Fold into elita (later, under real load)

Organs that migrate: daemon/attach bootstrap + distribution plumbing (this work),
claude-port session as a brain option on the per-agent dial (mlm/haiku/claude).
Organs that die: el's own Registry, @target> routing, DETS store — elita's
ask/tell and tape already are those. No umbrella; elita stays one app.

## Open questions

- node naming scheme when both macs run daemons (el@work.local vs el@home.local; discovery?)
- does work corp network ever leave the LAN picture (VPN forcing all traffic)? if so, tailscale fallback
- cookie hygiene: same cookie = full node access; fine for two personal macs, revisit before any third machine
