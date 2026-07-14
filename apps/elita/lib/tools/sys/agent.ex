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
  import Log, only: [log: 5]
  import Utils.File, only: [file: 1]

  defdelegate spec(name, state), to: Tools.Sys.Agent.Schema, as: :get

  def exec(_, %{"name" => name}, state) do
    agent = file("#{name}.md")
    log("🤖", name, ":", "\n#{agent}\n", :white)
    {agent, state}
  end
end
