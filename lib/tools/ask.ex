defmodule AskTool do
  import GenServer, only: [call: 3]

  def void?, do: false

  def def do
    %{
      name: "ask",
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

  def exec(%{"recipient" => recipient, "question" => question}) do
    recipient_atom = recipient |> String.downcase() |> String.to_atom()
    via_name = {:via, Registry, {ElitaRegistry, recipient_atom}}
    call(via_name, {:act, question}, :infinity)
  end
end