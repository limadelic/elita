defmodule Mlm do
  import Compose, only: [compose: 1]
  import System, only: [get_env: 2]
  import Req, only: [post: 2]

  @url "http://mlm:11434/api/chat"

  def llm(%{config: config, history: history} = state) do
    composed = compose(config)
    body = %{model: model(), messages: messages(composed.content, history), stream: false}
    result = req(body) |> resp
    {parts(result), state}
  end

  def llm(text) when is_binary(text) do
    body = %{model: model(), messages: [%{role: "user", content: text}], stream: false}
    req(body) |> resp |> text
  end

  defp req(body), do: post(@url, json: body, receive_timeout: 60_000)

  defp model, do: get_env("MLM_MODEL", "llama3.2:3b")

  defp messages(system, history), do: [%{role: "system", content: system} | history]

  defp text([%{"type" => "text", "text" => t} | _]), do: t
  defp text(other), do: other

  defp parts(content) when is_binary(content), do: [%{"text" => content}]
  defp parts({:error, _} = err), do: err

  defp resp({:ok, %{status: 200, body: %{"message" => %{"content" => content}}}}), do: content
  defp resp({:ok, %{status: code, body: body}}), do: {:error, "HTTP #{code}: #{inspect(body)}"}
  defp resp({:error, err}), do: {:error, "request failed: #{inspect(err)}"}
end
