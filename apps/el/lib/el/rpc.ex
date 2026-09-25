defmodule El.RPC do
  @moduledoc false

  import Application, only: [ensure_all_started: 1]
  import File, only: [cwd!: 0]
  import El.Commands.Ls, only: [remote: 1]
  import El.Commands.Ask, only: [ask: 2]
  import El.Commands.Nodes, only: [check: 1]

  def dispatch(command, cwd \\ cwd!()) do
    ensure_all_started(:elita)
    build(safe(command, cwd))
  end

  defp build(output) do
    "#{marker()}\n#{output}"
  end

  defp safe(command, cwd), do: handle(command, cwd)

  defp handle(["ls"], cwd), do: remote(cwd: cwd)
  defp handle(["ls", path], _cwd), do: remote(path: path)
  defp handle(["ask", agent, msg], _cwd), do: ask(agent, msg)
  defp handle(["spawn", addr], _cwd), do: check(addr)
  defp handle(_, _cwd), do: ""

  defp marker, do: "node: #{here()}"

  defp here, do: :erlang.node()
end
