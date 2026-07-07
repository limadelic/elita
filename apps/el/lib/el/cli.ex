defmodule El.CLI do
  import Application, only: [ensure_all_started: 1]
  import IO, only: [puts: 1]

  alias El.Command

  @usage """
  Usage:
    el ask <agent> <message>
    el tell <agent> <message>
    el claude [name]
    el ls
    el daemon
  """

  def main(argv) do
    ensure_all_started(:elita)

    argv
    |> parse()
    |> run()
  end

  defp parse(["ask", agent, msg]), do: {:ask, agent, msg}
  defp parse(["tell", agent, msg]), do: {:tell, agent, msg}
  defp parse(["claude"]), do: {:claude, :default}
  defp parse(["claude", name]), do: {:claude, name}
  defp parse(["ls"]), do: {:ls, nil}
  defp parse(["ls", path]), do: {:ls, path}
  defp parse(["daemon"]), do: :daemon
  defp parse(_), do: :usage

  defp run(:usage) do
    @usage |> puts()
  end

  defp run({:ask, agent, msg}), do: Command.ask(agent, msg)
  defp run({:tell, agent, msg}), do: Command.tell(agent, msg)
  defp run({:claude, name}), do: Command.claude(name)
  defp run({:ls, path}), do: Command.ls(path)
  defp run(:daemon), do: Command.daemon()
end
