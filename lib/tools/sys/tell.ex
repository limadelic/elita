defmodule Tools.Sys.Tell.Schema do
  def get(name, _state) do
    %{name: name, description: "Send message to another agent", parameters: params()}
  end

  defp params do
    %{type: "object", properties: properties(), required: ["recipient", "message"]}
  end

  defp properties do
    %{
      recipient: %{type: "string", description: "Agent name to send message to"},
      message: %{type: "string", description: "Message content"}
    }
  end
end

defmodule Tools.Sys.Tell do
  import Elita, only: [cast: 2]
  import Log, only: [log: 5]

  defdelegate def(name, state), to: Tools.Sys.Tell.Schema, as: :get

  def exec(_, %{"recipient" => recipient, "message" => message}, %{name: sender} = state) do
    log("📢", "#{sender} → #{recipient}", ": ", message, :yellow)
    cast(recipient, "[from #{sender}] #{message}")
    {"sent", state}
  end
end
