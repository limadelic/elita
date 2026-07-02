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
    paths(name)
    |> find_value(&safe_read/1)
    |> handle_missing(name)
  end

  defp paths(name) do
    map(@paths, fn path -> join(path, name) end) ++ nested(name)
  end

  defp nested(name) do
    Path.wildcard("agents/**/#{name}")
  end

  defp handle_missing(nil, name), do: "file not found: #{name}"
  defp handle_missing(content, _name), do: content

  defp join(path, name), do: "#{path}#{name}"

  defp safe_read({:ok, content}), do: content
  defp safe_read({:error, _}), do: nil

  defp safe_read(path) do
    read(path) |> safe_read()
  end
end
