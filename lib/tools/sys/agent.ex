defmodule Tools.Sys.Agent do
  import Utils.File, only: [file: 1]
  import Log, only: [log: 5]
  import Enum, only: [join: 2]
  import Cfgs, only: [value: 2]

  def def(name, state) do
    %{
      name: name,
      description: "Read agent definition file. #{help(state)}",
      parameters: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Agent name to read"}
        },
        required: ["name"]
      }
    }
  end

  def exec(_, %{"name" => name}, state) do
    agent = file("#{name}.md")
    log("🤖", name, ":", "\n#{agent}\n", :white)
    {agent, state}
  end

  defp help(%{config: configs}) do
    agents = value(:agents, configs)
    "Available Agents: #{join(agents, ", ")}"
  end
end
