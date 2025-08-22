defmodule Log do
  import IO, only: [puts: 1]

  def q(prompt) do
    prompt[:contents] 
      |> Kernel.||([])
      |> List.last()
      |> log()
    prompt
  end

  def a(result) do
    log(result)
    result
  end

  def t(name, args) do
    format(name, args)
      |> then(&colored("🛠️: #{&1}", 196))
  end

  defp format("tell", %{"message" => msg, "recipient" => to}) do
    truncated = msg
      |> String.replace("\\n", "\n")
      |> truncate()
    "#{truncated} → #{to}"
  end

  defp format(name, args) do
    yaml(name, args)
  end

  defp truncate(text) do
    case {String.contains?(text, "\n"), String.length(text)} do
      {false, len} when len > 60 -> String.slice(text, 0, 57) <> "..."
      _ -> text
    end
  end

  def r(result) do
    formatted = yaml(result)
    colored("🎯: #{formatted}", 226)
    result
  end

  defp yaml(name, args) when is_map(args) do
    entries = args
      |> Map.drop(["__struct__"])
      |> Enum.map(fn {k, v} -> "  #{k}: #{format_value(v)}" end)
      |> Enum.join("\n")
    "\n#{name}:\n#{entries}"
  rescue
    _ -> "\n#{inspect args}"
  end

  defp format_value(v) when is_binary(v) do
    cond do
      String.starts_with?(v, "[{") -> "|\n#{parse_json(v)}"
      byte_size(v) > 50 -> "|\n    #{String.replace(v, "\n", "\n    ")}"
      true -> "\"#{v}\""
    end
  end
  defp format_value(v), do: "\"#{v}\""

  defp parse_json(json) do
    case Jason.decode(json) do
      {:ok, data} -> to_yaml_block(data, 4)
      _ -> "    #{json}"
    end
  rescue
    _ -> "    #{json}"
  end

  defp to_yaml_block(list, indent) when is_list(list) do
    list
    |> Enum.map(fn item -> "#{String.duplicate(" ", indent)}- #{map_to_yaml(item, indent + 2)}" end)
    |> Enum.join("\n")
  end

  defp map_to_yaml(map, indent) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> "#{k}: \"#{v}\"" end)
    |> Enum.join("\n#{String.duplicate(" ", indent)}")
  end

  defp yaml(result) when is_binary(result) do
    cond do
      String.starts_with?(result, "---") -> "\n#{result}"
      String.starts_with?(result, "[{") -> "\n#{parse_json(result)}"
      byte_size(result) > 100 -> "\n#{result}"
      true -> "\"#{result}\""
    end
  rescue
    _ -> "\"#{result}\""
  end

  defp yaml(other) do
    inspect other
  rescue
    _ -> "unknown"
  end

  def tell(msg) do
    colored("📢: #{msg}", 226)
  end


  defp colored(text, code) do
    puts("\e[38;5;#{code}m#{text}\e[0m")
  end

  defp log(%{parts: [%{text: text}], role: "user"}) do
    colored("🤔: #{text}", 82)
  end

  defp log([%{"text" => text}]) do
    colored("✨: #{text}", 255)
  end

  defp log(_) do
    nil
  end

end
