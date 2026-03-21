defmodule Utils.File do
  import Enum, only: [map: 2, find_value: 2]
  import File, only: [read: 1]
  import String, only: [replace_suffix: 3]

  @paths [
    "",
    "agents/",
    "test/specs/",
    "test/silk/"
  ]

  def file(name) do
    ephemeral(name) || disk(name)
  end

  defp ephemeral(name) do
    key = replace_suffix(name, ".md", "")

    case :ets.lookup(:elita_agents, key) do
      [{^key, content}] -> content
      _ -> nil
    end
  rescue
    ArgumentError -> nil
  end

  defp disk(name) do
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
