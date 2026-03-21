defmodule Tools.Sys.Ask do
  import Elita, only: [call: 2]
  import Log, only: [log: 5]

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


  def exec(_, %{"recipient" => recipient, "question" => question}, %{name: sender} = state) do
    log("🤔", "#{sender} → #{recipient}", ": ", question, :green)

    try do
      {call(recipient, question), state}
    catch
      :exit, {:noproc, _} ->
        {"Error: agent '#{recipient}' is not running — spawn it first", state}

      :exit, reason ->
        {"Error: agent '#{recipient}' failed — #{inspect(reason)}", state}
    end
  end
end
