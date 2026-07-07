defmodule El.RPC do
  @moduledoc false

  import Application, only: [ensure_all_started: 1]

  alias El.Commands.Ask
  alias El.Commands.Ls

  def dispatch(command, cwd \\ File.cwd!()) do
    ensure_all_started(:elita)
    output = safe_execute(command, cwd)
    "#{marker()}\n#{output || ""}"
  end

  defp safe_execute(command, cwd) do
    try do
      execute(command, cwd)
    rescue
      _ -> ""
    end
  end

  defp execute(["ls"], cwd), do: Ls.execute_remote(cwd: cwd)
  defp execute(["ask", agent, msg], _cwd), do: Ask.execute(agent, msg)
  defp execute(_, _cwd), do: ""

  defp marker, do: "node: #{Node.self()}"
end
