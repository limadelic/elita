defmodule El.CLI do
  def main(argv) do
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

  defp parse(_) do
    :usage
  end

  defp execute(:usage) do
    IO.puts("Usage:")
    IO.puts("  el ask <agent> <message>")
    IO.puts("  el tell <agent> <message>")
  end

  defp execute({:ask, agent, msg}) do
    El.Commands.Ask.execute(agent, msg)
  end

  defp execute({:tell, agent, msg}) do
    El.Commands.Tell.execute(agent, msg)
  end
end
