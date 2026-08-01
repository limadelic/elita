#!/usr/bin/env elixir
# Stop the elita-cukes node gracefully via Erlang RPC

node_name = :"elita-cukes@127.0.0.1"

unless Node.alive? do
  Node.start(:"cukes_stopd@127.0.0.1")
end

case Node.connect(node_name) do
  true ->
    # Export coverage before shutdown
    {:ok, build_root} = File.cwd()
    coverage_dir = Path.join(build_root, "_build/test/coverage")
    File.mkdir_p(coverage_dir)
    edat_path = Path.join(coverage_dir, "cukes.edat")

    export_error = nil
    try do
      :erpc.call(node_name, :cover, :export, [String.to_charlist(edat_path)], 5000)
    rescue error ->
      export_error = error
    end

    :erpc.cast(node_name, :init, :stop, [])
    Process.sleep(500)

    if export_error do
      raise "Failed to export coverage: #{inspect(export_error)}"
    end

    System.halt(0)
  false ->
    # Node not running, nothing to stop
    System.halt(0)
end
