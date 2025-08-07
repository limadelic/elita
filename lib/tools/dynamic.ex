defmodule Dynamic do
  def tool(name) do
    path = "agents/tools/#{name}.md"
    if File.exists?(path) do
      %{name: name, description: "Dynamic tool: #{name}"}
    else
      nil
    end
  end

  def exec(name, _args) do
    path = "agents/tools/#{name}.md"
    if File.exists?(path) do
      "Dynamic tool #{name} executed"
    else
      {:error, "Tool #{name} not found"}
    end
  end
end