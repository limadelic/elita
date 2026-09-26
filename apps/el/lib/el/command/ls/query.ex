defmodule El.Command.Ls.Query do
  @moduledoc false
  import El.Remote, only: [call: 1]

  def fetch(path) do
    path |> route() |> call()
  end

  defp route(nil), do: ["ls"]
  defp route(path), do: ["ls", path]
end
