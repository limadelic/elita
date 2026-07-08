defmodule Utils.World do
  import Enum, only: [map: 2, sort: 1, filter: 2]
  import File, only: [ls: 1]
  import Path, only: [basename: 2]
  import String, only: [ends_with?: 2]

  def agents do
    "."
    |> ls()
    |> filter_md()
    |> sort()
  end

  defp filter_md({:ok, files}) do
    files
    |> filter(&ends_with?(&1, ".md"))
    |> map(&basename(&1, ".md"))
  end

  defp filter_md({:error, _}) do
    []
  end
end
