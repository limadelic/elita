defmodule Tools.User.Load.Schema do
  import Tools.User.Cfg, only: [parse: 1]
  import Tools.User.Def, only: [spec: 2]
  alias Path
  alias File

  @app_root Path.expand("../..", __DIR__)

  def get(name, state) do
    name
    |> path()
    |> load()
    |> spec(state)
  end

  def tool(name) do
    name |> path() |> load()
  end

  defp path(name) do
    Path.join(@app_root, "agents/tools/#{name}.md")
  end

  defp load(file_path) do
    exists_and_parse(File.exists?(file_path), file_path)
  end

  defp exists_and_parse(true, file_path), do: parse(file_path)
  defp exists_and_parse(false, _file_path), do: nil
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
