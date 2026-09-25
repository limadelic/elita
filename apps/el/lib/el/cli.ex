defmodule El.CLI do
  import Application, only: [ensure_all_started: 1]
  import IO, only: [puts: 1]
  import El.Commands.Ask, only: [ask: 3]
  import El.Commands.Tell, only: [send: 3]
  import El.Commands.Spawn, only: [spawn: 2]
  import El.Commands.Stop, only: [stop: 1]
  import El.Commands.Claude, only: [claude: 1]
  import El.Commands.Cd, only: [cd: 1]
  import El.Distribution, only: [launch: 0]
  import El.Command.Ls, only: [list: 1]
  import El.REPL, only: [run: 1, run: 2, attach: 2]
  import El.Trace, only: [setup: 2]
  import El.Ask, only: [invoke: 2]
  import El.Cli.Parse, only: [parse: 1, name: 1]
  import El.Bin, only: [locate: 0]
  import El.RPC, only: [dispatch: 1]
  import String, only: [split: 3]
  import Enum, only: [at: 3]

  @usage """
  Usage:
    el ask <agent> <message>
    el tell <agent> <message>
    el spawn <name> <agent>
    el stop <agent>
    el claude [name]
    el ls
    el cd <path>
    el node
  """

  def main(argv) do
    ensure_all_started(:elita)
    ensure_all_started(:matrix)
    argv |> route() |> exec()
  end

  defp route(["claude" | rest] = argv) do
    setup(name(argv), [locate() | rest])
    argv |> parse()
  end

  defp route(argv) do
    setup(name(argv), argv)
    argv |> parse()
  end

  defp exec(:usage) do
    @usage |> puts()
  end

  defp exec({:unknown_tool, tool}) do
    puts("unknown tool: #{tool}")
  end

  defp exec({:repl, agent}), do: run(agent)
  defp exec({:as, config, name}), do: attach(config, name)
  defp exec({:repl_input, agent, input}), do: run(agent, input)
  defp exec({:ask, tool, agent, msg}), do: ask(agent, msg, tool)
  defp exec({:tell, tool, agent, msg}), do: send(agent, msg, tool)
  defp exec({:spawn, name, agent}), do: spawn(name, agent)
  defp exec({:spawn_remote, addr}), do: ["spawn", addr] |> dispatch() |> render()
  defp exec({:stop, agent}), do: stop(agent)
  defp exec({:ask_tool, agent, msg}), do: invoke(agent, msg)
  defp exec({:claude, name}), do: claude(name)
  defp exec({:ls, path}), do: list(path)
  defp exec({:cd, path}), do: cd(path)
  defp exec(:node), do: launch()
  defp exec(_), do: :usage

  defp render(output) do
    output |> strip() |> reply()
  end

  defp strip(text) when is_binary(text) do
    text |> split("\n", parts: 2) |> at(1, "")
  end

  defp strip(_), do: ""

  defp reply(""), do: nil
  defp reply(msg), do: puts(msg)
end
