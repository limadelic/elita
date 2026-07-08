defmodule El.CLI do
  import Application, only: [ensure_all_started: 1]
  import IO, only: [puts: 1]
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
    if System.get_env("COVER") == "1" do
      with_cover(argv)
    else
      dispatch(argv)
    end
  end

  defp with_cover(argv) do
    El.Cover.start()
    result = dispatch(argv)
    file = coverage_filename()
    File.write(file <> ".marker", "exported")
    El.Cover.export_unique(file)
    File.write(file <> ".done", "success")
    result
  end


  defp coverage_filename do
    pid = :os.getpid() |> to_string()
    ts = :erlang.system_time(:millisecond)
    filename = "coverdata.#{pid}.#{ts}.ets"
    case System.get_env("COVER_DIR") do
      nil -> filename
      dir -> dir <> "/" <> filename
    end
  end

  defp dispatch(argv) do
    argv |> parse() |> run()
  end

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
