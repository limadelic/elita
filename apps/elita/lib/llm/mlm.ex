defmodule Mlm do
  import Compose, only: [compose: 1]
  import Tools, only: [tools: 2]
  import Enum, only: [map: 2]
  import System, only: [get_env: 2]
  import Req, only: [post: 2]
  import Map, only: [put: 3, get: 3, merge: 2]
  import String, only: [replace: 3, trim: 1]
  import MsgAdapter, only: [to_ollama: 1]
  @url "http://#{get_env("MLM_HOST", "localhost")}:11434/api/chat"
  def llm(text) when is_binary(text) do
    messages = [%{role: "user", content: "/no_think #{text}"}]
    %{model: model(), messages: messages, stream: false} |> req |> resp |> text
  end

  def llm(%{config: config, history: history} = state) do
    {build_body(compose(config), history, state) |> req |> resp |> parts, state}
  end

  defp build_body(composed, history, state) do
    base_body(model(), messages(composed.content, history))
    |> add_tools(tools(composed, state))
  end

  defp base_body(m, msgs), do: %{model: m, messages: msgs, stream: false}

  defp req(body), do: post(@url, json: put(body, :think, false), receive_timeout: 120_000)

  defp model, do: get_env("MLM_MODEL", "qwen3-fast")

  defp messages(system, history) do
    [%{role: "system", content: "/no_think\n#{system}"} | map(history, &to_ollama/1)]
  end

  defp add_tools(body, [%{function_declarations: defs}]),
    do: Map.put(body, :tools, map(defs, &tool/1))

  defp add_tools(body, _), do: body

  defp tool(d), do: %{type: "function", function: func_spec(d)}

  defp func_spec(d) do
    %{
      name: d[:name],
      description: d[:description],
      parameters: get(d, :parameters, %{type: "object"})
    }
  end

  defp text([%{"type" => "text", "text" => t} | _]), do: t
  defp text(other), do: other
  defp parts(list) when is_list(list), do: list
  defp parts(content) when is_binary(content), do: [%{"text" => content}]
  defp parts({:error, _} = err), do: err

  defp resp({:ok, %{status: 200, body: %{"message" => %{"tool_calls" => calls}}}}),
    do: map(calls, &build_tool_use/1)

  defp resp({:ok, %{status: 200, body: %{"message" => %{"content" => content}}}}),
    do: strip_think(content)

  defp resp({:ok, %{status: code, body: body}}), do: {:error, "HTTP #{code}: #{inspect(body)}"}
  defp resp({:error, err}), do: {:error, "request failed: #{inspect(err)}"}

  defp build_tool_use(%{"function" => %{"name" => name, "arguments" => args}}) do
    %{"tool_use" => %{"id" => name, "name" => name, "input" => decode(args)}}
  end

  defp decode(args) when is_map(args) do
    args
    |> Map.new(fn {k, v} -> {k, decode_val(v)} end)
    |> flatten_nested()
  end

  defp decode(args), do: args

  defp flatten_nested(args) do
    Enum.reduce(args, %{}, fn
      {_k, v}, acc when is_map(v) -> merge(acc, flatten_nested(v))
      {k, v}, acc -> put(acc, k, v)
    end)
  end

  defp strip_think(c) do
    c |> replace(~r/<think>.*?<\/think>\s*/s, "") |> trim() |> maybe_fallback(c)
  end

  defp maybe_fallback("", c) do
    c |> replace(~r/<\/?think>/s, "") |> trim()
  end

  defp maybe_fallback(s, _), do: s

  defp decode_val(v) when is_binary(v) do
    v |> replace("'", "\"") |> Jason.decode() |> decode_result(v)
  end

  defp decode_val(v), do: v

  defp decode_result({:ok, d}, _), do: d
  defp decode_result({:error, _}, fallback), do: fallback
end
