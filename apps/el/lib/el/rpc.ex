defmodule El.RPC do
  @moduledoc false

  import Application, only: [ensure_all_started: 1]

  alias El.Commands.Ask
  alias El.Commands.Ls

  def dispatch(command, cwd \\ File.cwd!()) do
    ensure_all_started(:elita)
    build(safe(command, cwd))
  end

  defp build(output) do
    "#{marker()}\n#{output}"
  end

  defp safe(command, cwd), do: handle(command, cwd)

  defp handle(["ls"], cwd), do: Ls.remote(cwd: cwd)
  defp handle(["ask", agent, msg], _cwd), do: Ask.execute(agent, msg)
  defp handle(_, _cwd), do: ""

  defp marker, do: "node: #{Node.self()}"
end
