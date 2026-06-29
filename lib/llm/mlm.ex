defmodule Mlm do
  import Compose, only: [compose: 1]
  import Tools, only: [tools: 2]
  import Enum, only: [map: 2]
  import System, only: [get_env: 2]
  import Req, only: [post: 2]

  @url "http://#{System.get_env("MLM_HOST", "localhost")}:11434/api/chat"

  def llm(text) when is_binary(text) do
    messages = [%{role: "user", content: "/no_think #{text}"}]
    %{model: model(), messages: messages, stream: false} |> req |> resp |> text
  end

  def llm(%{config: config, history: history} = state) do
    composed = compose(config)
    msgs = messages(composed.content, history)
    body = %{model: model(), messages: msgs, stream: false}
    |> add_tools(tools(composed, state))
    {req(body) |> resp |> parts, state}
  end

  defp req(body), do: post(@url, json: Map.put(body, :think, false), receive_timeout: 120_000)

  defp model, do: get_env("MLM_MODEL", "qwen3-fast")

  defp messages(system, history) do
    [%{role: "system", content: "/no_think\n#{system}"} | map(history, &MsgAdapter.to_ollama/1)]
  end

  defp add_tools(body, [%{function_declarations: defs}]) do
    Map.put(body, :tools, map(defs, &tool/1))
  end
  defp add_tools(body, _), do: body

  defp tool(d) do
    %{type: "function", function: func_spec(d)}
  end

  defp func_spec(d) do
    %{name: d[:name], description: d[:description],
      parameters: Map.get(d, :parameters, %{type: "object"})}
  end

  defp text([%{"type" => "text", "text" => t} | _]), do: t
  defp text(other), do: other

  defp parts(list) when is_list(list), do: list
  defp parts(content) when is_binary(content), do: [%{"text" => content}]
  defp parts({:error, _} = err), do: err

  defp resp({:ok, %{status: 200, body: %{"message" => %{"tool_calls" => calls}}}}),
    do: map(calls, fn %{"function" => %{"name" => name, "arguments" => args}} ->
      %{"tool_use" => %{"id" => name, "name" => name, "input" => decode(args)}}
    end)
  defp resp({:ok, %{status: 200, body: %{"message" => %{"content" => content}}}}), do: strip_think(content)
  defp resp({:ok, %{status: code, body: body}}), do: {:error, "HTTP #{code}: #{inspect(body)}"}
  defp resp({:error, err}), do: {:error, "request failed: #{inspect(err)}"}

  defp decode(args) when is_map(args) do
    args
    |> Map.new(fn {k, v} -> {k, decode_val(v)} end)
    |> flatten_nested()
  end
  defp decode(args), do: args

  defp flatten_nested(args) do
    Enum.reduce(args, %{}, fn
      {_k, v}, acc when is_map(v) -> Map.merge(acc, flatten_nested(v))
      {k, v}, acc -> Map.put(acc, k, v)
    end)
  end

  defp strip_think(c) do
    c |> Regex.replace(~r/<think>.*?<\/think>\s*/s, "") |> String.trim() |> maybe_fallback(c)
  end

  defp maybe_fallback("", c) do
    c |> String.replace(~r/<\/?think>/s, "") |> String.trim()
  end
  defp maybe_fallback(s, _), do: s

  defp decode_val(v) when is_binary(v) do
    v |> String.replace("'", "\"") |> Jason.decode() |> decode_result(v)
  end
  defp decode_val(v), do: v

  defp decode_result({:ok, d}, _), do: d
  defp decode_result({:error, _}, fallback), do: fallback
end
