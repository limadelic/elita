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

  defp filter_md({:ok, files}) do
    map(files, &basename(&1, ".md"))
  end

  defp filter_md({:error, _}) do
    []
  end
end
