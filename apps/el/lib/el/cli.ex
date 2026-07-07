defmodule El.CLI do
  import Application, only: [ensure_all_started: 1]
  import IO, only: [puts: 1]

  alias El.CLI.Daemon
  alias El.Commands.Ask
  alias El.Commands.Claude
  alias El.Commands.Ls
  alias El.Commands.Tell
  alias El.Distribution

  def main(argv) do
    ensure_all_started(:elita)

    argv
    |> parse()
    |> execute()
  end

  defp parse(["ask", agent, msg]) do
    {:ask, agent, msg}
  end

  defp parse(["tell", agent, msg]) do
    {:tell, agent, msg}
  end

  defp parse(["claude"]) do
    {:claude, :default}
  end

  defp parse(["claude", name]) do
    {:claude, name}
  end

  defp parse(["ls"]) do
    :ls
  end

  defp parse(["daemon"]) do
    :daemon
  end

  defp parse(_) do
    :usage
  end

  defp execute(:usage) do
    puts("Usage:")
    puts("  el ask <agent> <message>")
    puts("  el tell <agent> <message>")
    puts("  el claude [name]")
    puts("  el ls")
  end

  defp execute({:ask, agent, msg}) do
    Ask.execute(agent, msg)
  end

  defp execute({:tell, agent, msg}) do
    Tell.execute(agent, msg)
  end

  defp execute({:claude, name}) do
    Claude.execute(name)
  end

  defp execute(:ls) do
    Distribution.start()
    puts("local:> ")
    Ls.execute()
  end

  defp execute(:daemon) do
    Daemon.execute()
  end

  def dispatch(command, _args) do
    ensure_all_started(:elita)

    output =
      try do
        capture_io_output(fn -> exec_dispatch(command) end)
      rescue
        _ -> ""
      catch
        _ -> ""
      end

    "#{Node.self()}> " <> output
  end

  defp exec_dispatch(["ls"]) do
    Ls.execute()
  end

  defp exec_dispatch(["ask", agent, msg]) do
    Ask.execute(agent, msg)
  end

  defp exec_dispatch(["tell", agent, msg]) do
    Tell.execute(agent, msg)
  end

  defp exec_dispatch(_), do: nil

  defp capture_io_output(fun) do
    try do
      {:ok, device} = StringIO.open("")

      old_gl = :erlang.group_leader()
      :erlang.group_leader(device, self())

      try do
        fun.()
      after
        :erlang.group_leader(old_gl, self())
      end

      result = StringIO.close(device)

      case result do
        {:ok, output} -> output
        {_buffer, output} -> output
        output when is_binary(output) -> output
        _ -> ""
      end
    rescue
      _ -> ""
    catch
      _ -> ""
    end
  end
end
