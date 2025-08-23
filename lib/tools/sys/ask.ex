defmodule Tools.Sys.Ask do
  import Elita, only: [call: 2]
  import Log, only: [log: 4]

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
    log("🤔", "#{sender} → #{recipient}", question, :green)
  end

  def log(response) do
    response
  end

  def exec(_, %{"recipient" => recipient, "question" => question}, state) do
    {call(recipient, question), state}
  end
end
