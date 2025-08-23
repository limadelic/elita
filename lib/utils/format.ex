defmodule Format do

  def yaml(args) when is_map(args) do
    args
    |> Map.drop(["__struct__"])
    |> parse_json_values()
    |> Ymlr.document!()
    |> String.replace_prefix("---", "")
  rescue
    _ -> "#{inspect(args)}"
  end

  def yaml(args) when is_binary(args) do
    case Jason.decode(args) do
      {:ok, parsed} when is_map(parsed) or is_list(parsed) ->
        yaml(parsed)
      _ -> args
    end
  rescue
    _ -> args
  end

  def yaml(args), do: "#{inspect(args)}"

  defp parse_json_values(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, parse_json_value(v)} end)
  end

  defp parse_json_value(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, parsed} -> parsed
      _ -> value
    end
  end

  defp parse_json_value(value), do: value

end
