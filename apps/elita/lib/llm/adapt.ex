defmodule Adapt do
  import Enum, only: [map: 2, reduce: 3]
  import Map, only: [put: 3, merge: 2, new: 2]
  import String, only: [replace: 3, trim: 1]
  import Jason, only: [decode: 1]

  def resp({:ok, %{status: 200, body: %{"message" => %{"tool_calls" => calls}}}}) do
    map(calls, &build/1)
  end

  def resp({:ok, %{status: 200, body: %{"message" => %{"content" => content}}}}) do
    strip(content)
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

  defp build(%{"function" => %{"name" => name, "arguments" => args}}) do
    %{"tool_use" => %{"id" => name, "name" => name, "input" => args(args)}}
  end

  defp args(args) when is_map(args) do
    args
    |> new(fn {k, v} -> {k, parse(v)} end)
    |> flatten()
  end

  defp args(args) do
    args
  end

  defp flatten(args) do
    reduce(args, %{}, fn
      {_k, v}, acc when is_map(v) -> merge(acc, flatten(v))
      {k, v}, acc -> put(acc, k, v)
    end)
  end

  defp strip(c) do
    c |> replace(~r/<think>.*?<\/think>\s*/s, "") |> trim() |> fallback(c)
  end

  defp fallback("", c) do
    c |> replace(~r/<\/?think>/s, "") |> trim()
  end

  defp fallback(s, _) do
    s
  end

  defp parse(v) when is_binary(v) do
    v |> replace("'", "\"") |> decode() |> result(v)
  end

  defp parse(v) do
    v
  end

  defp result({:ok, d}, _) do
    d
  end

  defp result({:error, _}, fallback) do
    fallback
  end
end
