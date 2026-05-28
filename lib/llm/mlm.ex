defmodule Mlm do
  import Compose, only: [compose: 1]
  import Tools, only: [tools: 2]
  import Enum, only: [map: 2]
  import System, only: [get_env: 2]
  import Req, only: [post: 2]

  @url "http://#{System.get_env("MLM_HOST", "localhost")}:11434/api/chat"

  def llm(text) when is_binary(text) do
    body = %{model: model(), messages: [%{role: "user", content: text}], stream: false}
    req(body) |> resp |> text
  end

  def llm(%{config: config, history: history} = state) do
    composed = compose(config)
    body = %{model: model(), messages: messages(composed.content, history), stream: false}
          |> add_tools(tools(composed, state))
    {req(body) |> resp |> parts, state}
  end

  defp req(body), do: post(@url, json: body, receive_timeout: 60_000)

  defp model, do: get_env("MLM_MODEL", "llama3.2:3b")

  defp messages(system, history), do: [%{role: "system", content: system} | map(history, &MsgAdapter.to_ollama/1)]

  defp add_tools(body, [%{function_declarations: defs}]) do
    Map.put(body, :tools, map(defs, fn d ->
      %{type: "function", function: Map.put(d, :parameters, d[:parameters] || %{type: "object"})}
    end))
  end
  defp add_tools(body, _), do: body

  defp text([%{"type" => "text", "text" => t} | _]), do: t
  defp text(other), do: other

  defp parts(list) when is_list(list), do: list
  defp parts(content) when is_binary(content), do: [%{"text" => content}]
  defp parts({:error, _} = err), do: err

  defp resp({:ok, %{status: 200, body: %{"message" => %{"tool_calls" => calls}}}}),
    do: map(calls, fn %{"function" => %{"name" => name, "arguments" => args}} ->
      %{"tool_use" => %{"id" => name, "name" => name, "input" => decode(args)}}
    end)
  defp resp({:ok, %{status: 200, body: %{"message" => %{"content" => content}}}}), do: content
  defp resp({:ok, %{status: code, body: body}}), do: {:error, "HTTP #{code}: #{inspect(body)}"}
  defp resp({:error, err}), do: {:error, "request failed: #{inspect(err)}"}

  defp decode(args) when is_map(args), do: Map.new(args, fn {k, v} -> {k, decode_val(v)} end)
  defp decode(args), do: args

  defp decode_val(v) when is_binary(v) do
    json = String.replace(v, "'", "\"")
    case Jason.decode(json) do {:ok, d} -> d; _ -> v end
  end
  defp decode_val(v), do: v
end
