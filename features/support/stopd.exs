#!/usr/bin/env elixir
# Stop the elita-cukes daemon node gracefully via Erlang RPC

node_name = :"elita-cukes@127.0.0.1"

unless Node.alive? do
  Node.start(:"cukes_stopd@127.0.0.1")
end

case Node.connect(node_name) do
  true ->
    :erpc.cast(node_name, :init, :stop, [])
    Process.sleep(500)
    System.halt(0)
  false ->
    # Node not running, nothing to stop
    System.halt(0)
end
