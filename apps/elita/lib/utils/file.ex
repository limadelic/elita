defmodule Utils.File do
  import Enum, only: [map: 2, find_value: 2]
  import File, only: [read: 1]
  import Path, only: [expand: 2, wildcard: 1, join: 2]
  import System, only: [get_env: 2]

  @app_root expand("../..", __DIR__)

  @paths [
    "",
    "agents/",
    "test/specs/"
  ]

  def file(name, cwd \\ nil) do
    (here(cwd, name) ++ paths(name))
    |> find_value(&fetch/1)
    |> ensure(name)
  end

  def root, do: get_env("ELITA_HOME", @app_root)

  defp here(nil, _name), do: []
  defp here(cwd, name), do: [join(cwd, name)]

  defp paths(name) do
    map(@paths, fn path -> concat("#{root()}/#{path}", name) end) ++
      nested(name)
  end

  defp nested(name) do
    wildcard(join(root(), "agents/**/#{name}"))
  end

  defp ensure(nil, name), do: "file not found: #{name}"
  defp ensure(content, _name), do: content

  defp concat(path, name), do: "#{path}#{name}"

  defp fetch({:ok, content}), do: content
  defp fetch({:error, _}), do: nil

  defp fetch(path) do
    read(path) |> fetch()
  end
end
