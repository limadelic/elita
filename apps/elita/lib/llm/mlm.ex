defmodule Mlm do
  import Compose, only: [compose: 1]
  import Tools, only: [tools: 2]
  import System, only: [get_env: 2]
  import Req, only: [post: 2]
  import Map, only: [put: 3]

  alias Shape
  alias Adapt

  @url "http://#{get_env("MLM_HOST", "localhost")}:11434/api/chat"

  def llm(text) when is_binary(text) do
    messages = [%{role: "user", content: "/no_think #{text}"}]
    %{model: model(), messages: messages, stream: false} |> req |> Adapt.resp() |> Adapt.text()
  end

  def llm(%{config: config, history: history} = state) do
    {build_body(compose(config), history, state) |> req |> Adapt.resp() |> Adapt.parts(), state}
  end

  defp build_body(composed, history, state) do
    base_body(model(), Shape.messages(composed.content, history))
    |> Shape.add_tools(tools(composed, state))
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
