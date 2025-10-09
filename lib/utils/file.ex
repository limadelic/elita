defmodule Utils.File do
  import Enum, only: [map: 2, find_value: 2]
  import File, only: [read: 1]

  @paths [
    "",
    "agents/",
    "test/specs/",
    "test/silk/"
  ]

  def file(name) do
    @paths
    |> map(fn path -> join(path, name) end)
    |> find_value(fn path -> attempt(path) end)
    |> case do
      nil -> "file not found: #{name}"
      content -> content
    end
  end

  defp join(path, name), do: "#{path}#{name}"

  defp attempt(path) do
    case read(path) do
      {:ok, content} -> content
      {:error, _} -> nil
    end
  end
end
