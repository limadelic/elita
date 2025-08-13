defmodule Tools.User do
  import Tools.User.Cfg, only: [parse: 1]

  def def(name) do
    name |> tool() |> Tools.User.Def.def
  end

  def exec(name, args) do
    name |> tool() |> Tools.User.Exec.exec(args)
  end

  defp tool(name) do
    name |> path() |> load()
  end

  defp path(name), do: "agents/tools/#{name}.md"

  defp load(path) do
    if File.exists?(path), do: parse(path), else: nil
  end
end
