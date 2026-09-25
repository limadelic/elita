defmodule El.Command.Ls.Query do
  @moduledoc false
  import El.Command.Ls.Remote, only: [send: 1]

  def fetch(path) do
    path |> route() |> send()
  end

  defp route(nil), do: ["ls"]
  defp route(path), do: ["ls", path]
end
