defmodule Tools.Sys.Ask.Schema do
  def get(name, _state) do
    %{name: name, description: "Ask question to another agent and get response", parameters: params()}
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
  import Elita, only: [call: 2]
  import Log, only: [log: 5]

  defdelegate spec(name, state), to: Tools.Sys.Ask.Schema, as: :get

  def exec(_, %{"recipient" => recipient, "question" => question}, %{name: sender} = state) do
    log("🤔", "#{sender} → #{recipient}", ": ", question, :green)
    {call(recipient, question), state}
  end

  def exec(_, _args, state) do
    {"ask needs recipient and question", state}
  end
end
