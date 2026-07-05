defmodule Tools.Sys.Wake.Schema do
  def get(name, _state) do
    %{
      name: name,
      description: "Wake an agent with a message",
      parameters: params()
    }
  end

  defp params do
    %{type: "object", properties: properties(), required: ["name", "message"]}
  end

  defp properties do
    %{
      name: %{type: "string", description: "Agent name to wake"},
      message: %{type: "string", description: "Message to send"}
    }
  end
end

defmodule Tools.Sys.Wake do
  import Agent.Registry, only: [lookup: 1]
  import Agent.Session, only: [ask: 2]
  import Elita, only: [call: 2]

  defdelegate spec(name, state), to: Tools.Sys.Wake.Schema, as: :get

  def exec(_, %{"name" => name, "message" => message}, state) do
    {response(lookup(String.to_atom(name)), message), state}
  end

  def exec(_, _args, state) do
    {"wake needs name and message", state}
  end

  defp response({:ok, {_pid, nil}}, message) do
    call(String.to_atom("native"), message)
  end

  defp response({:ok, {pid, _folder}}, message) do
    {:ok, response} = ask(pid, message)
    response
  end

  defp response({:error, :not_found}, _message) do
    "agent not found"
  end
end
