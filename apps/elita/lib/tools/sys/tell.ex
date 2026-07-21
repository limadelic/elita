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

  def exec(_, %{"recipient" => r, "message" => m}, %{name: s, skip_logs: l} = state) do
    note(@icon, s, r, m, l)
    dispatch(r, "[from #{s}] #{m}", :tell)
    {"sent", state}
  end

  def exec(_, _, state) do
    {"tell needs recipient and message", state}
  end

  defp note(_icon, _sender, _recipient, _message, true) do
    :ok
  end

  defp note(_icon, "el", _recipient, _message, _) do
    :ok
  end

  defp note(icon, sender, recipient, message, false) do
    log(icon, "#{sender} → #{recipient}", ": ", message, :yellow)
    agent(icon, "#{sender} → #{recipient}", ": ", message, %{name: sender})
  end
end
