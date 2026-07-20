defmodule El.CLI do
  import Application, only: [ensure_all_started: 1]
  import IO, only: [puts: 1]
  import El.Commands.Ask, only: [ask: 3]
  import El.Commands.Tell, only: [send: 3]
  import El.Commands.Spawn, only: [spawn: 2]
  import El.Commands.Stop, only: [stop: 1]
  import El.Commands.Claude, only: [claude: 1]
  import El.Commands.Cd, only: [cd: 1]
  import El.Distribution, only: [daemon: 0]
  import El.Command.Ls, only: [list: 1]
  import El.REPL, only: [run: 1, run: 2]
  import El.Log, only: [setup: 2]
  import Enum, only: [join: 2]
  import El.Ask, only: [invoke: 2]

  @usage """
  Usage:
    el ask <agent> <message>
    el tell <agent> <message>
    el spawn <name> <agent>
    el stop <agent>
    el [tool] ask <agent> <message>
    el [tool] tell <agent> <message>
    el claude [name]
    el ls
    el cd <path>
    el daemon
  """

  @known_tools ["claude", "codex"]

  def main(argv) do
    ensure_all_started(:elita)
    argv |> route() |> exec()
  end

  defp route(argv) do
    name = name(argv)
    setup(name, argv)
    argv |> parse()
  end

  defp name(["claude", name | _]), do: name
  defp name(["claude"]), do: "default"
  defp name(["ask", agent | _]), do: agent
  defp name(["tell", agent | _]), do: agent
  defp name(["spawn", _name, agent]), do: agent
  defp name(["@" <> agent | _]), do: agent
  defp name([tool, "ask", agent | _]) when tool in @known_tools, do: agent
  defp name([tool, "tell", agent | _]) when tool in @known_tools, do: agent
  defp name(["ls" | _]), do: "default"
  defp name(["cd" | _]), do: "default"
  defp name(["daemon"]), do: "default"
  defp name([agent | rest]) when length(rest) > 0, do: agent
  defp name([agent]), do: agent
  defp name([]), do: "el"

  defp parse(["ask", agent, msg]), do: {:ask, nil, agent, msg}
  defp parse(["tell", agent, msg]), do: {:tell, nil, agent, msg}
  defp parse(["spawn", name, agent]), do: {:spawn, name, agent}
  defp parse(["stop", agent]), do: {:stop, agent}
  defp parse(["@" <> agent | rest]), do: {:ask_tool, agent, rest |> join(" ")}
  defp parse([tool, "ask", agent, msg]), do: check(tool, {:ask, tool, agent, msg})
  defp parse([tool, "tell", agent, msg]), do: check(tool, {:tell, tool, agent, msg})
  defp parse(["claude"]), do: {:claude, :default}
  defp parse(["claude", name]), do: {:claude, name}
  defp parse(["ls"]), do: {:ls, nil}
  defp parse(["ls", path]), do: {:ls, path}
  defp parse(["cd", path]), do: {:cd, path}
  defp parse(["daemon"]), do: :daemon
  defp parse([]), do: {:repl, "el"}
  defp parse([agent | rest]) when length(rest) > 0, do: {:repl_input, agent, join([agent | rest], " ")}
  defp parse([agent]), do: {:repl, agent}
  defp parse(_), do: :usage

  defp check(tool, cmd) when tool in @known_tools, do: cmd
  defp check(tool, _cmd), do: {:unknown_tool, tool}

  defp exec(:usage) do
    @usage |> puts()
  end

  defp exec({:unknown_tool, tool}) do
    puts("unknown tool: #{tool}")
  end

  defp exec({:repl, agent}), do: run(agent)
  defp exec({:repl_input, agent, input}), do: run(agent, input)
  defp exec({:ask, tool, agent, msg}), do: ask(agent, msg, tool)
  defp exec({:tell, tool, agent, msg}), do: send(agent, msg, tool)
  defp exec({:spawn, name, agent}), do: spawn(name, agent)
  defp exec({:stop, agent}), do: stop(agent)
  defp exec({:ask_tool, agent, msg}), do: invoke(agent, msg)
  defp exec({:claude, name}), do: claude(name)
  defp exec({:ls, path}), do: list(path)
  defp exec({:cd, path}), do: cd(path)
  defp exec(:daemon), do: daemon()
  defp exec(_), do: :usage
end
