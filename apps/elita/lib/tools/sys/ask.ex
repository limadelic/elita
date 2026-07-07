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
  import Agent.Session, only: [ask: 2]
  import Tools.Sys.Safe, only: [call: 2]
  import String, only: [to_atom: 1, downcase: 1]

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
    normalized = recipient |> to_atom |> to_string |> downcase
    Registry.lookup(ElitaRegistry, normalized)
    |> handle(recipient, question)
  end

  defp handle([{_pid, %{kind: :native}}], recipient, question) do
    Elita.call(to_atom(recipient), question)
  end

  defp handle([{pid, %{kind: :headless}}], _recipient, question) do
    {:ok, response} = ask(pid, question)
    response
  end

  defp handle([], recipient, question) do
    guard(recipient, question)
  end

  defp guard(recipient, question) do
    call(fn -> Elita.call(String.to_atom(recipient), question) end, "agent not found")
  end
end
