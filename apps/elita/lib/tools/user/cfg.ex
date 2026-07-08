defmodule Tools.User.Cfg do
  import Enum, only: [join: 2, map: 2, reduce: 3]
  import File, only: [read!: 1]
  import List, only: [first: 1]
  import Map, only: [new: 2, put: 3]
  import Regex, only: [replace: 3, scan: 3]
  import String, only: [split: 2, to_atom: 1, trim: 1]

  @code ~r/```elixir\n(.*?)\n```/s

  def parse(path) do
    path |> read!() |> sever() |> extract()
  end

  defp sever(content) do
    split(content, "---")
  end

  defp extract([_, header | rest]) do
    yaml(header)
    |> atomize()
    |> with_blocks(rest)
    |> with_body(rest)
  end

  defp with_blocks(cfg, rest) do
    put(cfg, :code, blocks(join(rest, "---")))
  end

  defp with_body(cfg, rest) do
    put(cfg, :body, body(join(rest, "---")))
  end

  defp blocks(markdown) do
    scan(@code, markdown, capture: :all_but_first)
    |> map(&first/1)
  end

  defp body(markdown) do
    replace(@code, markdown, "") |> trim()
  end

  defp atomize(map) do
    map |> new(fn {k, v} -> {to_atom(k), v} end)
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
