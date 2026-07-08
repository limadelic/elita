defmodule Mlm do
  import Compose, only: [compose: 1]
  import Map, only: [put: 3]
  import Req, only: [post: 2]
  import System, only: [get_env: 2]
  import Tools, only: [tools: 2]

  import Adapt, only: [resp: 1, text: 1, parts: 1]
  import Shape, only: [messages: 2, add_tools: 2]

  @url "http://#{get_env("MLM_HOST", "localhost")}:11434/api/chat"

  def llm(text) when is_binary(text) do
    body(text) |> req() |> resp() |> text()
  end

  def llm(%{config: config, history: history} = state) do
    {build_body(compose(config), history, state)
     |> req()
     |> resp()
     |> parts(), state}
  end

  defp body(text) do
    messages = [%{role: "user", content: "/no_think #{text}"}]
    %{model: model(), messages: messages, stream: false}
  end

  defp build_body(composed, history, state) do
    base_body(model(), messages(composed.content, history))
    |> add_tools(tools(composed, state))
  end

  defp base_body(m, msgs) do
    %{model: m, messages: msgs, stream: false}
  end

  defp req(body) do
    post(@url, json: put(body, :think, false), receive_timeout: 120_000)
  end

  defp model do
    get_env("MLM_MODEL", "qwen3-fast")
  end
end
