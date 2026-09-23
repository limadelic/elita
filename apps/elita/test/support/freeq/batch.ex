defmodule Freeq.Batch do
  def assemble(lines) do
    {:result, acc} = process(lines, {:result, []}, nil, [])
    Enum.reverse(acc)
  end

  defp process([], {:result, acc}, _id, _msgs) do
    {:result, acc}
  end

  defp process([line | rest], {:result, acc}, nil, _) do
    if String.starts_with?(line, "BATCH +") do
      id = extract_id(line)
      process(rest, {:result, acc}, id, [])
    else
      process(rest, {:result, [line | acc]}, nil, [])
    end
  end

  defp process([line | rest], {:result, acc}, id, msgs) do
    if String.starts_with?(line, "BATCH -") do
      assembled = merge(msgs)
      process(rest, {:result, [assembled | acc]}, nil, [])
    else
      process(rest, {:result, acc}, id, [line | msgs])
    end
  end

  defp extract_id(line) do
    line |> String.split() |> Enum.at(1) |> String.slice(1..-1//-1)
  end

  defp merge(msgs) do
    bodies = msgs |> Enum.reverse() |> Enum.map(&body/1)
    text = Enum.join(bodies, "\n")
    line = List.last(msgs)
    prefix(line, text)
  end

  defp prefix(line, text) do
    case String.split(line, " :") do
      parts when length(parts) >= 2 ->
        prefix_part = parts |> Enum.drop(-1) |> Enum.join(" :")
        "#{prefix_part} :#{text}"
      _ -> line
    end
  end

  defp body(line) do
    case String.split(line, " :") do
      parts when length(parts) >= 2 -> List.last(parts)
      _ -> line
    end
  end
end
