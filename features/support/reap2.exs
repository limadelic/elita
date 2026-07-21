#!/usr/bin/env elixir
# Clean room: stop daemon and reap orphaned processes

node_name = :"elita-cukes@127.0.0.1"

unless Node.alive? do
  Node.start(:"reap@127.0.0.1")
end

case Node.connect(node_name) do
  true ->
    :erpc.cast(node_name, :init, :stop, [])
    Process.sleep(500)
  false ->
    :ok
end

System.halt(0)
