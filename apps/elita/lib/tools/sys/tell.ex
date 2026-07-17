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
  import Log, only: [log: 5, agent: 5]

  @icon "📢"

  defdelegate spec(name, state), to: Tools.Sys.Tell.Schema, as: :get

  def icon, do: @icon

  def exec(_, %{"recipient" => recipient, "message" => message}, %{name: sender} = state) do
    note(@icon, sender, recipient, message)
    dispatch(recipient, "[from #{sender}] #{message}", :tell)
    {"sent", state}
  end

  def exec(_, _args, state) do
    {"tell needs recipient and message", state}
  end

  defp note(_icon, "el", _recipient, _message) do
    :ok
  end

  defp note(icon, sender, recipient, message) do
    log(icon, "#{sender} → #{recipient}", ": ", message, :yellow)
    agent(icon, "#{sender} → #{recipient}", ": ", message, %{name: sender})
  end
end
