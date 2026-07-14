defmodule Tools.Sys.Ask.Schema do
  def get(name, _state) do
    %{name: name, description: description(), parameters: params()}
  end

  defp description do
    "Ask question to another agent and get response"
  end

  defp params do
    %{type: "object", properties: properties(), required: required()}
  end

  defp required do
    ["recipient", "question"]
  end

  defp properties do
    %{
      recipient: %{type: "string", description: "Agent name to ask question to"},
      question: %{type: "string", description: "Question to ask"}
    }
  end
end

defmodule Tools.Sys.Ask do
  import Agent.Harness, only: [dispatch: 3]
  import Log, only: [write: 1]
  import String, only: [trim: 1]

  defdelegate spec(name, state), to: Tools.Sys.Ask.Schema, as: :get

  def exec(_, %{"recipient" => recipient, "question" => question}, %{name: sender} = state) do
    route(recipient, question, sender, state)
  end

  def exec(_, _args, state) do
    {"ask needs recipient and question", state}
  end

  defp route(recipient, question, sender, state) do
    write("🤔 #{sender} → #{recipient} | #{question}\n")
    answer = dispatch(recipient, question, :ask)
    reply(bare(recipient), answer)
    {answer, state}
  end

  defp bare("el." <> name), do: name
  defp bare(name), do: name

  defp reply(agent, text) when is_binary(text) do
    write("✨ #{agent} | #{trim(text)}\n")
  end

  defp reply(_agent, _answer), do: :ok
end
