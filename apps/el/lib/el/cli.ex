defmodule El.CLI do
  import Application, only: [ensure_all_started: 1]
  import IO, only: [puts: 1]
  import El.Commands.Ask, only: [ask: 3]
  import El.Commands.Tell, only: [tell: 3]
  import El.Commands.Spawn, only: [spawn: 2]
  import El.Commands.Claude, only: [claude: 1]
  import El.Commands.Cd, only: [cd: 1]
  import El.Distribution, only: [daemon: 0]
  import El.Command.Ls, only: [list: 1]
  import El.REPL, only: [run: 1]

  @usage """
  Usage:
    el ask <agent> <message>
    el tell <agent> <message>
    el spawn <name> <agent>
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
    name = session_name(argv)
    El.Log.setup(name, argv)
    argv |> parse()
  end

  defp session_name(["claude", name | _]), do: name
  defp session_name(["claude"]), do: "default"
  defp session_name(_), do: "default"

  defp parse(["ask", agent, msg]), do: {:ask, nil, agent, msg}
  defp parse(["tell", agent, msg]), do: {:tell, nil, agent, msg}
  defp parse(["spawn", name, agent]), do: {:spawn, name, agent}

  defp parse([tool, "ask", agent, msg]) do
    check(tool, {:ask, tool, agent, msg})
  end

  defp parse([tool, "tell", agent, msg]) do
    check(tool, {:tell, tool, agent, msg})
  end

  defp parse(["claude"]), do: {:claude, :default}
  defp parse(["claude", name]), do: {:claude, name}
  defp parse(["ls"]), do: {:ls, nil}
  defp parse(["ls", path]), do: {:ls, path}
  defp parse(["cd", path]), do: {:cd, path}
  defp parse(["daemon"]), do: :daemon
  defp parse([]), do: {:repl, "el"}
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
  defp exec({:ask, tool, agent, msg}), do: ask(agent, msg, tool)
  defp exec({:tell, tool, agent, msg}), do: tell(agent, msg, tool)
  defp exec({:spawn, name, agent}), do: spawn(name, agent)
  defp exec({:claude, name}), do: claude(name)
  defp exec({:ls, path}), do: list(path)
  defp exec({:cd, path}), do: cd(path)
  defp exec(:daemon), do: daemon()
  defp exec(_), do: :usage
end
