defmodule Utils.Yaml do
  import Kernel
  import String, only: [replace_prefix: 3, to_atom: 1, replace: 3]
  import Map, only: [new: 2]
  import Enum, only: [map: 2]
  import Ymlr, only: [document!: 1]
  import Jason, only: [decode: 1]

  def yaml(args) when is_map(args) do
    encode_yaml(args)
  end

  def yaml(args) when is_list(args) do
    encode_yaml(args)
  end

  def yaml(args) when is_binary(args) do
    result = try_json(args)
    fallback(result, args)
  end

  def yaml(nil), do: nil

  def yaml(args), do: inspect(args)

  defp encode_yaml(args) do
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

  defp try_json(args) do
    first = json(args)
    handle_json(first, args)
  end

  defp handle_json(nil, args) do
    yaml(json(replaced(args)))
  end

  defp handle_json(parsed, _args) do
    yaml(parsed)
  end

  defp replaced(args) do
    replace(args, "'", "\"")
  end

  defp json(args) do
    decode(args) |> parse_json()
  end

  defp parse_json({:ok, json}), do: json
  defp parse_json(_), do: nil

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
