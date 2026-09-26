defmodule Tools.User.Load.Schema do
  import Tools.User.Cfg, only: [parse: 1]
  import Tools.User.Def, only: [spec: 2]
  import Tools.User.Validate, only: [check: 1]
  import Path, only: [join: 2]
  import File, only: [exists?: 1]
  import Utils.File, only: [root: 0]

  def get(name, state) do
    name |> path() |> load() |> check() |> spec(state)
  end

  def tool(name) do
    name |> path() |> load() |> check()
  end

  defp path(name) do
    join(root(), "agents/tools/#{name}.md")
  end

  defp load(file) do
    gather(exists?(file), file)
  end

  defp gather(true, file), do: parse(file)
  defp gather(false, _file), do: nil
end

defmodule Tools.User do
  import Tools.User.Exec, only: [exec: 2]
  import Tools.User.Load.Schema, only: [tool: 1]

  defdelegate spec(name, state), to: Tools.User.Load.Schema, as: :get

  def exec(name, args, state) do
    result = exec(tool(name), args)
    {result, state}
  end
end
