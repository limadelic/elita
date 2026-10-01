defmodule Freeq.Result do
  import String, only: [trim_trailing: 2]
  import List, only: [wrap: 1]
  import Enum, only: [any?: 2, map: 2]
  import Map, only: [put: 3]
  import Freeq.Tags, only: [result?: 1, strip: 1]

  def clean(line), do: line |> to_string() |> trim_trailing("\r\n") |> wrap()

  def mark(state, line, lines) do
    marked = any?([to_string(line) | lines], &result?/1)
    put(state, :result, marked)
  end

  def untag(lines), do: map(lines, &strip/1)
end
