defmodule El.CLI do
  import Application, only: [ensure_all_started: 1]
  import IO, only: [puts: 1]

  alias El.Command

  @usage """
  Usage:
    el ask <agent> <message>
    el tell <agent> <message>
    el [tool] ask <agent> <message>
    el [tool] tell <agent> <message>
    el claude [name]
    el ls
    el cd <path>
    el daemon
  """

  def main(argv) do
    ensure_all_started(:elita)

    argv
    |> parse()
    |> run()
  end

  defp parse(["ask", agent, msg]), do: {:ask, nil, agent, msg}
  defp parse(["tell", agent, msg]), do: {:tell, nil, agent, msg}
  defp parse([tool, "ask", agent, msg]), do: {:ask, tool, agent, msg}
  defp parse([tool, "tell", agent, msg]), do: {:tell, tool, agent, msg}
  defp parse(["claude"]), do: {:claude, :default}
  defp parse(["claude", name]), do: {:claude, name}
  defp parse(["ls"]), do: {:ls, nil}
  defp parse(["ls", path]), do: {:ls, path}
  defp parse(["cd", path]), do: {:cd, path}
  defp parse(["daemon"]), do: :daemon
  defp parse(_), do: :usage

  defp run(:usage) do
    @usage |> puts()
  end

  defp run({:ask, tool, agent, msg}), do: Command.ask(agent, msg, tool)
  defp run({:tell, tool, agent, msg}), do: Command.tell(agent, msg, tool)
  defp run({:claude, name}), do: Command.claude(name)
  defp run({:ls, path}), do: Command.ls(path)
  defp run({:cd, path}), do: Command.cd(path)
  defp run(:daemon), do: Command.daemon()
end
