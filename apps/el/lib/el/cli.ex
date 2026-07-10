defmodule El.CLI do
  import Application, only: [ensure_all_started: 1]
  import IO, only: [puts: 1]
  import System, only: [get_env: 1]
  import El.Command
  alias El.REPL

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
    argv |> read() |> run()
  end

  defp read(argv) do
    route(argv, get_env("TAPE"), get_env("MIX_ENV"))
  end

  defp route(argv, tape, _mix_env) when tape != nil do
    parse(argv, true)
  end

  defp route(argv, _tape, "test") do
    parse(argv, true)
  end

  defp route(argv, _tape, _mix_env) do
    parse(argv, false)
  end

  defp parse(["ask", agent, msg], _test?), do: {:ask, nil, agent, msg}
  defp parse(["tell", agent, msg], _test?), do: {:tell, nil, agent, msg}
  defp parse(["spawn", name, agent], _test?), do: {:spawn, name, agent}

  defp parse([tool, "ask", agent, msg], _test?) do
    check(tool, {:ask, tool, agent, msg})
  end

  defp parse([tool, "tell", agent, msg], _test?) do
    check(tool, {:tell, tool, agent, msg})
  end

  defp parse(["claude"], _test?), do: {:claude, :default}
  defp parse(["claude", name], _test?), do: {:claude, name}
  defp parse(["ls"], _test?), do: {:ls, nil}
  defp parse(["ls", path], _test?), do: {:ls, path}
  defp parse(["cd", path], _test?), do: {:cd, path}
  defp parse(["daemon"], _test?), do: :daemon
  defp parse([], _test?), do: {:repl, "el"}
  defp parse([agent], _test?), do: {:repl, agent}
  defp parse(_, _test?), do: :usage

  defp check(tool, cmd) when tool in @known_tools, do: cmd
  defp check(tool, _cmd), do: {:unknown_tool, tool}

  defp run(:usage) do
    @usage |> puts()
  end

  defp run({:unknown_tool, tool}) do
    puts("unknown tool: #{tool}")
  end

  defp run({:repl, agent}), do: REPL.run(agent)
  defp run({:ask, tool, agent, msg}), do: ask(agent, msg, tool)
  defp run({:tell, tool, agent, msg}), do: tell(agent, msg, tool)
  defp run({:spawn, name, agent}), do: spawn(name, agent)
  defp run({:claude, name}), do: claude(name)
  defp run({:ls, path}), do: ls(path)
  defp run({:cd, path}), do: cd(path)
  defp run(:daemon), do: daemon()
  defp run(_), do: :usage
end
