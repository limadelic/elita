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
  import String, only: [to_atom: 1]
  import Agent.Router, only: [route: 3]

  defdelegate spec(name, state), to: Tools.Sys.Ask.Schema, as: :get

  def exec(_, %{"recipient" => recipient, "question" => question}, %{name: sender} = state) do
    log("🤔", sender <> " → " <> recipient, ": ", question, :green)
    result = route(to_atom(recipient), :ask, question)
    response = format_response(result, recipient)
    {response, state}
  end

  def exec(_, _args, state) do
    {"ask needs recipient and question", state}
  end

  defp format_response({:ok, resp}, _recipient), do: resp
  defp format_response({:error, :not_found}, recipient), do: recipient <> " not found"
  defp format_response(resp, _recipient), do: resp
end
