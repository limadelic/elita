defmodule Tools.Sys.Agent.Schema do
  import Enum, only: [join: 2]
  import Cfgs, only: [value: 2]

  def get(name, state) do
    %{name: name, description: desc(state), parameters: params()}
  end

  defp desc(state) do
    "Read agent definition file. #{help(state)}"
  end

  defp params do
    %{type: "object", properties: properties(), required: ["name"]}
  end

  defp properties do
    %{name: %{type: "string", description: "Agent name to read"}}
  end

  defp help(%{config: configs}) do
    agents = value(:agents, configs)
    "Available Agents: #{join(agents, ", ")}"
  end
end

defmodule Tools.Sys.Agent do
  import Utils.File, only: [file: 1]
  import Log, only: [log: 5]

  defdelegate def(name, state), to: Tools.Sys.Agent.Schema, as: :get

  def exec(_, %{"name" => name}, state) do
    agent = file("#{name}.md")
    log("🤖", name, ":", "\n#{agent}\n", :white)
    {agent, state}
  end
end
