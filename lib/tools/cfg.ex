defmodule Tools.Cfg do
  import String, only: [split: 2, trim: 1]
  import File, only: [read!: 1]
  import Enum, only: [join: 2, map: 2, reduce: 3]
  import Regex, only: [scan: 3]
  import Map, only: [put: 3]

  @code ~r/```elixir\n(.*?)\n```/s

  def parse(path) do
    path |> read! |> sever |> extract
  end

  defp sever(content) do
    split(content, "---")
  end

  defp extract([_, header | rest]) do
    {yaml(header), join(rest, "---")}
  end

  def blocks(body) do
    scan(@code, body, capture: :all_but_first)
    |> map(&List.first/1)
  end

  defp yaml(header) do
    split(trim(header), "\n") |> reduce(%{}, &line/2)
  end

  defp line(text, acc) do
    split(text, ":") |> build(acc)
  end

  defp build([key, value], acc), do: put(acc, trim(key), trim(value))
  defp build(_, acc), do: acc
end
