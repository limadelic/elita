defmodule Tools.Sys.Agent do
  import Utils.File, only: [file: 1]
  import Log, only: [log: 5]

  def def(name, _state) do
    %{
      name: name,
      description: "Read agent definition file",
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
    log("🤖", name, ":\n", agent, :white)
    {agent, state}
  end
end
