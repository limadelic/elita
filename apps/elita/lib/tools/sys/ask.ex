defmodule Tools.Sys.Ask.Schema do
  def get(name, _state) do
    %{
      name: name,
      description: "Ask question to another agent and get response",
      parameters: params()
    }
  end

  defp params do
    %{type: "object", properties: properties(), required: ["recipient", "question"]}
  end

  defp properties do
    %{
      recipient: %{type: "string", description: "Agent name to ask question to"},
      question: %{type: "string", description: "Question to ask"}
    }
  end
end

defmodule Tools.Sys.Ask do
  import Log, only: [log: 5]
  import Agent.Registry, only: [lookup: 1]

  defdelegate spec(name, state), to: Tools.Sys.Ask.Schema, as: :get

  def exec(_, %{"recipient" => recipient, "question" => question}, %{name: sender} = state) do
    log("🤔", "#{sender} → #{recipient}", ": ", question, :green)
    response = route(recipient, question)
    {response, state}
  end

  def exec(_, _args, state) do
    {"ask needs recipient and question", state}
  end

  defp route(recipient, question) do
    case lookup(String.to_atom(recipient)) do
      {:ok, {_pid, nil}} ->
        Elita.call(String.to_atom(recipient), question)

      {:ok, {pid, _folder}} ->
        {:ok, response} = Agent.Session.ask(pid, question)
        response

      {:error, :not_found} ->
        try do
          Elita.call(String.to_atom(recipient), question)
        rescue
          _error -> "agent not found"
        catch
          :exit, _reason -> "agent not found"
        end
    end
  end
end
