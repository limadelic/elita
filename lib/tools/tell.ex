defmodule Tools.Tell do
  import GenServer, only: [cast: 2]

  def void?, do: true

  def def do
    %{
      name: "tell",
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

  def exec(%{"recipient" => recipient, "message" => message}) do
    recipient_atom = recipient |> String.downcase() |> String.to_atom()
    via_name = {:via, Registry, {ElitaRegistry, recipient_atom}}
    cast(via_name, {:act, message})
    "sent"
  end
end