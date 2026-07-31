#!/usr/bin/env elixir
# Stop the elita-cukes node gracefully via Erlang RPC

node_name = :"elita-cukes@127.0.0.1"

unless Node.alive? do
  Node.start(:"cukes_stopd@127.0.0.1")
end

case Node.connect(node_name) do
  true ->
    # Export coverage before shutdown
    coverage_dir = "/Users/mike/dev/self/elita/donny/_build/test/coverage"
    File.mkdir_p(coverage_dir)
    edat_path = "#{coverage_dir}/cukes.edat"
    try do
      :erpc.call(node_name, :cover, :export, [String.to_charlist(edat_path)], 5000)
    rescue _ -> nil
    end

    :erpc.cast(node_name, :init, :stop, [])
    Process.sleep(500)
    System.halt(0)
  false ->
    # Node not running, nothing to stop
    System.halt(0)
end
