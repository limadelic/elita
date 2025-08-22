defmodule Format do
  def yaml(name, args) when is_map(args) do
    entries =
      args
      |> Map.drop(["__struct__"])
      |> Enum.map(fn {k, v} -> "  #{k}: #{value(v)}" end)
      |> Enum.join("\n")

    "\n#{name}:\n#{entries}"
  rescue
    _ -> "\n#{inspect(args)}"
  end

  def yaml(result) when is_binary(result) do
    cond do
      String.starts_with?(result, "---") -> "\n#{result}"
      String.starts_with?(result, "[{") -> "\n#{json(result)}"
      byte_size(result) > 100 -> "\n#{result}"
      true -> "\"#{result}\""
    end
  rescue
    _ -> "\"#{result}\""
  end

  def yaml(other) do
    inspect(other)
  rescue
    _ -> "unknown"
  end

  defp value(v) when is_binary(v) do
    cond do
      String.starts_with?(v, "[{") -> "|\n#{json(v)}"
      byte_size(v) > 50 -> "|\n    #{String.replace(v, "\n", "\n    ")}"
      true -> "\"#{v}\""
    end
  end

  defp value(v), do: "\"#{v}\""

  defp json(text) do
    case Jason.decode(text) do
      {:ok, data} -> block(data, 4)
      _ -> "    #{text}"
    end
  rescue
    _ -> "    #{text}"
  end

  defp block(list, indent) when is_list(list) do
    list
    |> Enum.map(fn item -> "#{String.duplicate(" ", indent)}- #{map(item, indent + 2)}" end)
    |> Enum.join("\n")
  end

  defp map(data, indent) when is_map(data) do
    data
    |> Enum.map(fn {k, v} -> "#{k}: \"#{v}\"" end)
    |> Enum.join("\n#{String.duplicate(" ", indent)}")
  end

  def truncate(text) do
    case {String.contains?(text, "\n"), String.length(text)} do
      {false, len} when len > 60 -> String.slice(text, 0, 57) <> "..."
      _ -> text
    end
  end
end
