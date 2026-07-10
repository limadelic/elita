defmodule Utils.Yaml do
  import Enum, only: [map: 2]
  import Jason, only: [decode: 1]
  import Map, only: [new: 2]
  import String, only: [replace_prefix: 3, to_atom: 1, replace: 3]
  import Ymlr, only: [document!: 1]

  def yaml(args) when is_map(args) do
    express(args)
  end

  def yaml(args) when is_list(args) do
    express(args)
  end

  def yaml(args) when is_binary(args) do
    result = probe(args)
    fallback(result, args)
  end

  def yaml(nil), do: nil

  def yaml(args), do: "#{inspect(args)}"

  defp express(args) do
    render(args)
  rescue
    _ -> inspect(args)
  end

  defp render(args) do
    args
    |> atomize()
    |> document!()
    |> replace_prefix("---", "")
  end

  defp fallback(nil, args), do: args
  defp fallback(result, _args), do: result

  defp probe(args) do
    first = json(args)
    process(first, args)
  end

  defp process(nil, args) do
    yaml(json(replaced(args)))
  end

  defp process(parsed, _args) do
    yaml(parsed)
  end

  defp replaced(args) do
    replace(args, "'", "\"")
  end

  defp json(args) do
    decode(args) |> extract()
  end

  defp extract({:ok, json}), do: json
  defp extract(_), do: nil

  defp atomize(map) when is_map(map) do
    new(map, fn {k, v} -> {to_atom(k), atomize(v)} end)
  rescue
    _ -> map
  end

  defp atomize(list) when is_list(list) do
    map(list, fn item -> atomize(item) end)
  end

  defp atomize(value), do: value
end
