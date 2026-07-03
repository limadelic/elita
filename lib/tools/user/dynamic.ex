defmodule Tools.User.Load.Schema do
  import Tools.User.Cfg, only: [parse: 1]

  def get(name, state) do
    name
    |> path()
    |> load()
    |> Tools.User.Def.def(state)
  end

  def tool(name) do
    name |> path() |> load()
  end

  defp path(name), do: "agents/tools/#{name}.md"

  defp load(path) do
    exists_and_parse(File.exists?(path), path)
  end

  defp exists_and_parse(true, path), do: parse(path)
  defp exists_and_parse(false, _path), do: nil
end

defmodule Tools.User do
  import Tools.User.Exec, only: [exec: 2]
  import Tools.User.Load.Schema, only: [tool: 1]

  defdelegate def(name, state), to: Tools.User.Load.Schema, as: :get

  def exec(name, args, state) do
    result = exec(tool(name), args)
    {result, state}
  end
end
