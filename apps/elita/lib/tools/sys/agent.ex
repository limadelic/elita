defmodule Tools.Sys.Agent.Schema do
  def get(name, _state) do
    %{name: name, description: desc(), parameters: params()}
  end

  defp desc do
    "Read agent definition file."
  end

  defp params do
    %{type: "object", properties: properties(), required: ["name"]}
  end

  defp properties do
    %{name: %{type: "string", description: "Agent name to read"}}
  end
end

defmodule Tools.Sys.Agent do
  import Log, only: [log: 5, agent: 5]
  import Utils.File, only: [file: 1]

  @icon "🤖"

  defdelegate spec(name, state), to: Tools.Sys.Agent.Schema, as: :get

  def icon, do: @icon

  def exec(_, %{"name" => name}, %{name: agent} = state) do
    content = file("#{name}.md")
    notify(content, name, agent)
    {content, state}
  end

  defp notify(content, name, agent) do
    log(@icon, name, ":", "\n#{content}\n", :white)
    agent(@icon, name, ":", "\n#{content}\n", %{name: agent})
  end
end
