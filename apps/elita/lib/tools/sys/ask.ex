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
  import Log, only: [write: 1, agent: 5]
  import String, only: [trim: 1]

  @icon "🤔"
  @reply "✨"

  defdelegate spec(name, state), to: Tools.Sys.Ask.Schema, as: :get

  def icon, do: @icon

  def exec(_, %{"recipient" => r, "question" => q}, %{name: s, skip_logs: l} = state) do
    query(s, r, q, l)
    result = dispatch(r, q, :ask)
    reply(r, s, result, l)
    {result, state}
  end

  def exec(_, _, state) do
    {"ask needs recipient and question", state}
  end

  def query(sender, recipient, question) do
    query(sender, recipient, question, false)
  end

  def query(sender, recipient, question, silent) do
    record(sender, recipient, question, silent)
  end

  defp record(_sender, _recipient, _question, true) do
    :ok
  end

  defp record("el", _recipient, _question, _) do
    :ok
  end

  defp record(sender, recipient, question, _) do
    msg = "#{@icon} #{sender} → #{recipient} | #{question}\n"
    write(msg)
    el(msg)
    agent(@icon, "#{sender} → #{recipient}", " | ", question, %{name: sender})
  end

  def answer(agent, text) when is_binary(text) do
    emit(agent, text)
    log(agent, text)
  end

  def answer(_agent, _text), do: :ok

  defp emit(agent, text) do
    msg = "#{@reply} #{agent} | #{trim(text)}\n"
    write(msg)
    el(msg)
  end

  defp log(agent, text) do
    agent(@reply, agent, " | ", text, %{name: agent})
  rescue
    _ -> :ok
  end

  defp reply(replier, asker, text, silent) when is_binary(text) do
    log(replier, asker, text, silent)
  end

  defp reply(_replier, _asker, _text, _silent), do: :ok

  defp log(_replier, _asker, _text, true) do
    :ok
  end

  defp log(replier, asker, text, _) do
    msg = "#{@reply} #{replier} → #{asker} | #{trim(text)}\n"
    write(msg)
    el(msg)
    agent(@reply, "#{replier} → #{asker}", " | ", text, %{name: asker})
  end

  defp el(msg) do
    :erlang.apply(:"Elixir.El.Log", :write, [msg])
  rescue
    _ -> :ok
  end
end
