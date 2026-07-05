defmodule Adapt do
  import Enum, only: [map: 2, reduce: 3]
  import Map, only: [put: 3, merge: 2, new: 2]
  import String, only: [replace: 3, trim: 1]

  def resp({:ok, %{status: 200, body: %{"message" => %{"tool_calls" => calls}}}}) do
    map(calls, &build_tool_use/1)
  end

  def resp({:ok, %{status: 200, body: %{"message" => %{"content" => content}}}}) do
    strip_think(content)
  end

  def resp({:ok, %{status: code, body: body}}) do
    {:error, "HTTP #{code}: #{inspect(body)}"}
  end

  def resp({:error, err}) do
    {:error, "request failed: #{inspect(err)}"}
  end

  def text([%{"type" => "text", "text" => t} | _]) do
    t
  end

  def text(other) do
    other
  end

  def parts(list) when is_list(list) do
    list
  end

  def parts(content) when is_binary(content) do
    [%{"text" => content}]
  end

  def parts({:error, _} = err) do
    err
  end

  defp build_tool_use(%{"function" => %{"name" => name, "arguments" => args}}) do
    %{"tool_use" => %{"id" => name, "name" => name, "input" => decode(args)}}
  end

  defp decode(args) when is_map(args) do
    args
    |> new(fn {k, v} -> {k, decode_val(v)} end)
    |> flatten_nested()
  end

  defp decode(args) do
    args
  end

  defp flatten_nested(args) do
    reduce(args, %{}, fn
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

  defp maybe_fallback(s, _) do
    s
  end

  defp decode_val(v) when is_binary(v) do
    v |> replace("'", "\"") |> Jason.decode() |> decode_result(v)
  end

  defp decode_val(v) do
    v
  end

  defp decode_result({:ok, d}, _) do
    d
  end

  defp decode_result({:error, _}, fallback) do
    fallback
  end
end
