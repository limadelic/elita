defmodule El.Command.Ls.Query do
  @moduledoc false
  import :erpc, only: [call: 4]
  import Node, only: [connect: 1]
  import File, only: [cwd!: 0]

  def fetch(path) do
    connect(:"elita@127.0.0.1") |> dial(path)
  rescue
    _ -> :error
  end

  defp dial(true, path) do
    cwd = cwd!()
    cmd = route(path)
    output = call(:"elita@127.0.0.1", El.RPC, :dispatch, [cmd, cwd])
    {:ok, output}
  end

  defp dial(_, _), do: :error

  defp route(nil), do: ["ls"]
  defp route(path), do: ["ls", path]
end
