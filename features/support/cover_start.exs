#!/usr/bin/env elixir
# Start coverage instrumentation on the elita-cukes node

node_name = :"elita-cukes@127.0.0.1"

unless Node.alive?() do
  case Node.start(:"cover_start-#{:erlang.unique_integer([:positive])}@127.0.0.1") do
    {:ok, _} -> nil
    {:error, _} -> nil
  end
end

if Node.connect(node_name) do
  # Start coverage
  :erpc.call(node_name, :cover, :start, [], 5000)

  # Compile beam directories for coverage
  {:ok, build_root} = File.cwd()
  ebin_dirs = [
    Path.join(build_root, "_build/test/lib/el/ebin"),
    Path.join(build_root, "_build/test/lib/elita/ebin"),
    Path.join(build_root, "_build/test/lib/matrix/ebin")
  ]

  Enum.each(ebin_dirs, fn dir ->
    :erpc.call(node_name, :cover, :compile_beam_directory, [String.to_charlist(dir)], 5000)
  end)
end

System.halt(0)
