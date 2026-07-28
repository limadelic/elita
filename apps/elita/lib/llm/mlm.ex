defmodule Mlm do
  import Application, only: [get_env: 2]
  import Compose, only: [compose: 1]
  import Map, only: [put: 3]
  import Req, only: [post: 2]
  import Tools, only: [tools: 2]

  import Adapt, only: [resp: 1, text: 1, parts: 1]
  import Shape, only: [messages: 2, equip: 2]

  def llm(text) when is_binary(text) do
    body(text) |> req() |> resp() |> text()
  end

  def llm(%{config: config, history: history} = state) do
    {equipped(compose(config), history, state)
     |> req()
     |> resp()
     |> parts(), state}
  end

  defp body(text) do
    messages = [%{role: "user", content: "/no_think #{text}"}]
    %{model: model(), messages: messages, stream: false}
  end

  defp equipped(composed, history, state) do
    base(model(), messages(composed.content, history))
    |> equip(tools(composed, state))
  end

  defp base(m, msgs) do
    %{model: m, messages: msgs, stream: false}
  end

  defp url do
    host = get_env(:elita, :mlm_host)
    "http://#{host}:11434/api/chat"
  end

  defp req(body) do
    post(url(), json: put(body, :think, false), receive_timeout: 120_000)
  end

  defp model do
    get_env(:elita, :mlm_model)
  end
end
