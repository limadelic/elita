defmodule Tools.Sys.Tell do
  import GenServer, only: [cast: 2]


  def def(name, _state) do
    %{
      name: name,
      description: "Send message to another agent",
      parameters: %{
        type: "object",
        properties: %{
          recipient: %{type: "string", description: "Agent name to send message to"},
          message: %{type: "string", description: "Message content"}
        },
        required: ["recipient", "message"]
      }
    }
  end

  def exec(_, %{"recipient" => recipient, "message" => message}, _state) do
    recipient_name = recipient |> String.downcase()
    via_name = {:via, Registry, {ElitaRegistry, recipient_name}}
    cast(via_name, {:act, message})
    "sent"
  end
end