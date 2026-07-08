defmodule Utils.World do
  import Enum, only: [map: 2, sort: 1]
  import File, only: [ls: 1]
  import Path, only: [basename: 2]

  def agents do
    "."
    |> ls()
    |> filter_md()
    |> sort()
  end

  defp filter_md(result) do
    case result do
      {:ok, files} -> map(files, &basename(&1, ".md"))
      {:error, _} -> []
    end
  end
end
