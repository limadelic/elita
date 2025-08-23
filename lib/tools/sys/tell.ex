defmodule Tools.Sys.Tell do
  import Elita, only: [cast: 2]
  import Log, only: [tell: 2]

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

  def log({%{"args" => %{"recipient" => recipient, "message" => message}}, %{name: sender}}) do
    tell(message, "#{sender} → #{recipient}")
  end

  def log(_) do
  end

  def exec(_, %{"recipient" => recipient, "message" => message}, state) do
    cast(recipient, message)
    {"sent", state}
  end
end
