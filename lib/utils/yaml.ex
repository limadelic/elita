defmodule Utils.Yaml do
  import String, only: [replace_prefix: 3, to_atom: 1]
  import Map, only: [new: 2]
  import Enum, only: [map: 2]
  import Ymlr, only: [document!: 1]
  import Jason, only: [decode: 1]

  def yaml(args) when is_map(args) or is_list(args) do
    args
    |> atomize()
    |> document!()
    |> replace_prefix("---", "")
  rescue
    _ -> "#{inspect args}"
  end

  def yaml(args) when is_binary(args) do
    case decode(args) do
      {:ok, parsed} when is_map(parsed) or is_list(parsed) ->
        yaml(parsed)
      _ -> args
    end
  rescue
    _ -> args
  end

  def yaml(args), do: "#{inspect args}"

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
