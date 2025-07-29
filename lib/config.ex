defmodule AgentConfig do
  def config(name) do
    case File.read("agents/#{name}.md") do
      {:ok, content} -> content
      {:error, _} -> "You are a #{name} agent."
    end
  end
end