defmodule Tools.Sys.Tell do
  import Elita, only: [cast: 2]
  import Log, only: [log: 5]
  import String, only: [downcase: 1]

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
    log("📢", "#{sender} → #{recipient}", ": ", message, :yellow)
  end

  def log(_) do
  end

  def exec(_, %{"recipient" => recipient, "message" => message}, state) do
    cast(downcase(recipient), message)
    {"sent", state}
  end
end
