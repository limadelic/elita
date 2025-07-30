defmodule ToolsTest do
  use ExUnit.Case

  import Def, only: [tools: 1]

  test "set" do
    config = %{tools: "set"}

    result = tools(config)

    assert result == [
             %{
               function_declarations: [
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
               ]
             }
           ]
  end
end
