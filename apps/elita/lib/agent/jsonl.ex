defmodule Agent.Jsonl do
  import File, only: [exists?: 1, read!: 1]
  import String, only: [split: 2]
  import Enum, only: [drop: 2, with_index: 2, find_value: 3, count: 1]
  import Agent.Jsonl.Scan, only: [find: 0]
  import Jason, only: [decode: 1]

  def find(question, folder, pos) when is_binary(folder) do
    source(folder) |> load(question, pos)
  end

  def find(question, nil, pos) do
    source(nil) |> load(question, pos)
  end

  def find(question, pos) do
    source(nil) |> load(question, pos)
  end

  defp source(folder) do
    find(folder)
  end

  defp load(nil, _, _), do: :wait

  defp load(p, q, pos) do
    ok(exists?(p), p, q, pos)
  catch
    :exit, _ -> :wait
    _, _ -> :wait
  end

  defp ok(true, p, q, pos), do: p |> read!() |> split("\n") |> scan(q, pos)
  defp ok(false, _, _, _), do: :wait

  defp scan(lines, q, pos) do
    lines |> drop(pos) |> with_index(pos) |> rows(q)
  end

  defp rows(indexed, q) do
    find_value(indexed, {:continue, count(indexed)}, &row(&1, q))
  end

  defp row({line, _}, _) when byte_size(line) < 10, do: nil

  defp row({line, _}, _) do
    line |> decode() |> type()
  rescue
    _ -> nil
  end

  defp type({:ok, %{"type" => "assistant", "message" => %{"content" => c}}}),
    do: text(c)

  defp type({:ok, %{"type" => "assistant", "content" => c}}), do: text(c)

  defp type(_), do: nil

  defp text(c) when is_list(c) do
    t = find_value(c, "", &pick/1)
    empty(t)
  end

  defp text(_), do: nil

  defp empty(t) when byte_size(t) > 0, do: {:found, t}
  defp empty(_), do: nil

  defp pick(%{"text" => t}) when is_binary(t), do: t
  defp pick(%{"type" => "text", "text" => t}), do: t
  defp pick(_), do: nil
end
