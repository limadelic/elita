defmodule Tools.Sys.Tell.Schema do
  def get(name, _state) do
    %{name: name, description: description(), parameters: params()}
  end

  defp description do
    "Send message to another agent"
  end

  defp params do
    %{type: "object", properties: properties(), required: required()}
  end

  defp required do
    ["recipient", "message"]
  end

  defp properties do
    %{
      recipient: %{type: "string", description: "Agent name to send message to"},
      message: %{type: "string", description: "Message content"}
    }
  end
end

defmodule Tools.Sys.Tell do
  import Agent.Harness, only: [dispatch: 3]
  import Log, only: [log: 5]

  @icon "📢"

  defdelegate spec(name, state), to: Tools.Sys.Tell.Schema, as: :get

  def icon, do: @icon

  def exec(_, %{"recipient" => recipient, "message" => message}, %{name: sender} = state) do
    msg = "[from #{sender}] #{message}"
    log(@icon, "#{sender} → #{recipient}", ": ", message, :yellow)
    dispatch(recipient, msg, :tell)
    {"sent", state}
  end

  def exec(_, _args, state) do
    {"tell needs recipient and message", state}
  end
end
