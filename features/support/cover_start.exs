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
  try do
    :erpc.call(node_name, :cover, :start, [], 5000)
  rescue _ -> nil
  end

  # Compile beam directories for coverage
  ebin_dirs = [
    "/Users/mike/dev/self/elita/donny/_build/test/lib/el/ebin",
    "/Users/mike/dev/self/elita/donny/_build/test/lib/elita/ebin",
    "/Users/mike/dev/self/elita/donny/_build/test/lib/matrix/ebin"
  ]

  Enum.each(ebin_dirs, fn dir ->
    try do
      :erpc.call(node_name, :cover, :compile_beam_directory, [String.to_charlist(dir)], 5000)
    rescue _ -> nil
    end
  end)
end

System.halt(0)
