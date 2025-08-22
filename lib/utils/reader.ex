defmodule Utils.Reader do
  import File, only: [read: 1]

  @search_paths [
    "agents/",
    "test/specs/", 
    "tests/specs/", 
    "agents/specs/",
    ""
  ]

  def read_file(name) do
    @search_paths
    |> Enum.map(&"#{&1}#{name}")
    |> Enum.find_value(&try_read/1)
    |> case do
      nil -> "file not found: #{name}"
      content -> content
    end
  end

  defp try_read(path) do
    case read(path) do
      {:ok, content} -> content
      {:error, _} -> nil
    end
  end
end