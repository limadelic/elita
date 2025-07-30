defmodule SetTool do
  def def do
    %{
      name: "set",
      description: "Store data with a key",
      parameters: %{
        type: "object",
        properties: %{
          key: %{type: "string", description: "The key to store data under"},
          value: %{type: "string", description: "The value to store"}
        },
        required: ["key", "value"]
      }
    }
  end

  def exec(agent_name, %{"key" => key, "value" => value}) do
    table = Mem.table(agent_name)
    :ets.insert(table, {key, value})
    %{"key" => key, "result" => "stored"}
  end
end