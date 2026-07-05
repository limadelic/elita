defmodule Tools.Sys.Wake.Schema do
  def get(name, _state) do
    %{
      name: name,
      description: "Wake an agent with a message",
      parameters: params()
    }
  end

  defp params do
    %{type: "object", properties: properties(), required: ["agent", "message"]}
  end

  defp properties do
    %{
      agent: %{type: "string", description: "Agent name to wake"},
      message: %{type: "string", description: "Message to send to agent"}
    }
  end
end

defmodule Tools.Sys.Wake do
  import Log, only: [log: 5]
  import String, only: [to_atom: 1]
  import Agent.Registry, only: [lookup: 1]
  import Agent.Session, only: [ask: 2]

  defdelegate spec(name, state), to: Tools.Sys.Wake.Schema, as: :get

  def exec(_, %{"agent" => agent, "message" => msg}, state) do
    result = lookup(to_atom(agent))
    message = handle_lookup(result, msg)
    log("💬", agent, ": ", message, :cyan)
    {message, state}
  end

  def exec(_, _args, state) do
    {"wake needs agent and message", state}
  end

  defp handle_lookup({:ok, {pid, _folder}}, msg) do
    {:ok, response} = ask(pid, msg)
    response
  end

  defp handle_lookup({:error, :not_found}, _msg) do
    "agent not found"
  end
end
