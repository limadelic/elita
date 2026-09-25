defmodule El.Command.Ls.Remote do
  @moduledoc false
  import :erpc, only: [call: 4]
  import Node, only: [connect: 1]
  import File, only: [cwd!: 0]
  import El.Run, only: [address: 0]

  def send(cmd) do
    connect(address()) |> dial(cmd)
  catch
    _, _ -> :error
  end

  defp dial(true, cmd) do
    cwd = cwd!()
    output = call(address(), El.RPC, :dispatch, [cmd, cwd])
    {:ok, output}
  end

  defp dial(_, _), do: :error
end
