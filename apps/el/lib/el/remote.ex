defmodule El.Remote do
  @moduledoc false
  import :erpc, only: [call: 4]
  import Node, only: [connect: 1]
  import File, only: [cwd!: 0]
  import El.Run, only: [address: 0, options: 0]

  def call(cmd) do
    connect(address()) |> dial(cmd)
  catch
    _, _ -> :error
  end

  defp dial(true, cmd) do
    cwd = cwd!()
    opts = options()
    result = call(address(), El.RPC, :dispatch, [cmd, cwd, opts])
    normalize(result)
  end

  defp dial(_, _), do: :error

  defp normalize({:error, text}), do: {:error, text}
  defp normalize(text) when is_binary(text), do: {:ok, text}
end
