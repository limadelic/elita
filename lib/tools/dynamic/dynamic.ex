defmodule Tools.Dynamic do
  import Tools.Dynamic.Cfg, only: [parse: 1, blocks: 1]
  import Tools.Dynamic.Exec, only: [execute: 2]

  def def(name) do
    name |> path |> build(name)
  end

  def exec(name, _args) do
    name |> path |> run
  end


  defp build(path, name) do
    build(path, name, File.exists?(path))
  end

  defp build(path, name, true) do
    {meta, _body} = parse(path)
    %{name: name, description: meta["description"] || "Dynamic tool: #{name}"}
  end

  defp build(_, _, false), do: nil

  defp run(path) do
    run(path, File.exists?(path))
  end

  defp run(path, true) do
    {meta, body} = parse(path)
    body |> blocks |> first(meta)
  end

  defp run(_, false), do: {:error, "Tool not found"}

  defp first([], _), do: "No code found"
  defp first([code | _], meta), do: execute(code, meta)

  defp path(name), do: "agents/tools/#{name}.md"
end
