defmodule El.CLI do
  import Application, only: [ensure_all_started: 1]
  import IO, only: [puts: 1]

  alias El.Commands.Ask
  alias El.Commands.Tell
  alias El.Commands.Claude

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

  defp parse(_) do
    :usage
  end

  defp execute(:usage) do
    puts("Usage:")
    puts("  el ask <agent> <message>")
    puts("  el tell <agent> <message>")
    puts("  el claude [name]")
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
end
