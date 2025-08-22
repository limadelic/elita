defmodule Tools.Sys.Ask do
  import Elita, only: [call: 2]
  import Log, only: [q: 2, a: 1]

  def def(name, _state) do
    %{
      name: name,
      description: "Ask question to another agent and get response",
      parameters: %{
        type: "object",
        properties: %{
          recipient: %{type: "string", description: "Agent name to ask question to"},
          question: %{type: "string", description: "Question to ask"}
        },
        required: ["recipient", "question"]
      }
    }
  end

  def log({%{"args" => %{"recipient" => recipient, "question" => question}}, %{name: sender}}) do
    q(question, "#{sender} → #{recipient}")
  end

  def log({response, state}) do
    a(response)
    {response, state}
  end

  def exec(_, %{"recipient" => recipient, "question" => question}, state) do
    {call(recipient, question), state}
  end
end
