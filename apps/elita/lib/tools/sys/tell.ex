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
  import Agent.Session, only: [cast: 2]
  import Tools.Sys.Safe, only: [call: 2]
  import String, only: [to_atom: 1, downcase: 1]

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
    normalized = recipient |> to_atom |> to_string |> downcase
    Registry.lookup(ElitaRegistry, normalized)
    |> handle(recipient, message)
  end

  defp handle([{_pid, %{kind: :native}}], recipient, message) do
    Elita.cast(to_atom(recipient), message)
  end

  defp handle([{pid, %{kind: :headless}}], _recipient, message) do
    cast(pid, message)
  end

  defp handle([], recipient, message) do
    defend(recipient, message)
  end

  defp defend(recipient, message) do
    call(fn -> Elita.cast(String.to_atom(recipient), message) end, nil)
  end
end
