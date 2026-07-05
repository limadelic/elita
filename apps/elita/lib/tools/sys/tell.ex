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
  import Log, only: [log: 5]
  import Agent.Registry, only: [lookup: 1]

  defdelegate spec(name, state), to: Tools.Sys.Tell.Schema, as: :get

  def exec(_, %{"recipient" => recipient, "message" => message}, %{name: sender} = state) do
    log("📢", "#{sender} → #{recipient}", ": ", message, :yellow)
    route(recipient, "[from #{sender}] #{message}")
    {"sent", state}
  end

  def exec(_, _args, state) do
    {"tell needs recipient and message", state}
  end

  defp route(recipient, message) do
    case lookup(String.to_atom(recipient)) do
      {:ok, {_pid, nil}} ->
        Elita.cast(String.to_atom(recipient), message)

      {:ok, {pid, _folder}} ->
        Agent.Session.cast(pid, message)

      {:error, :not_found} ->
        try do
          Elita.cast(String.to_atom(recipient), message)
        rescue
          _error -> nil
        catch
          :exit, _reason -> nil
        end
    end
  end
end
