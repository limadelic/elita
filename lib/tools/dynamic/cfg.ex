defmodule Tools.Dynamic.Cfg do
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
    markdown = join(rest, "---")
    yaml(header) 
    |> atomize 
    |> put(:code, blocks(markdown))
    |> put(:body, body(markdown))
  end

  defp blocks(markdown) do
    scan(@code, markdown, capture: :all_but_first)
    |> map(&List.first/1)
  end

  defp body(markdown) do
    Regex.replace(@code, markdown, "") |> String.trim()
  end

  defp atomize(map) do
    map
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
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
