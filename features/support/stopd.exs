#!/usr/bin/env elixir

defmodule Stop do
  def validate(nil), do: "cukes"
  def validate("") do
    IO.puts("refuse: live node")
    System.halt(1)
  end
  def validate(name), do: name
end

run_name = Stop.validate(System.get_env("ELITA_RUN"))
node_name = :"elita-#{run_name}@127.0.0.1"

unless Node.alive? do
  Node.start(:"cukes_stopd@127.0.0.1")
end

case Node.connect(node_name) do
  true ->
    :erpc.cast(node_name, :init, :stop, [])
    Process.sleep(500)
    System.halt(0)
  false ->
    System.halt(0)
end
