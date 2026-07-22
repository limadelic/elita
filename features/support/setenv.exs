#!/usr/bin/env elixir

cassette = System.argv() |> Enum.at(0)
cassette_dir = System.argv() |> Enum.at(1)

target_node = :"elita-cukes@127.0.0.1"

unless Node.alive?() do
  case Node.start(:"setenv-#{:erlang.unique_integer([:positive])}@127.0.0.1") do
    {:ok, _} -> nil
    {:error, _} -> nil
  end
end

if Node.connect(target_node) || (
  :erlang.set_cookie(target_node, String.to_atom("CJVFTZXWKXEWGUZCOGHS"))
  Node.connect(target_node)
) do
  if cassette, do: :erpc.call(target_node, System, :put_env, ["CASSETTE", cassette])
  if cassette_dir, do: :erpc.call(target_node, System, :put_env, ["CASSETTE_DIR", cassette_dir])
end

System.halt(0)
