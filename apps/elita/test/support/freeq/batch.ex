defmodule Freeq.Batch do
  def assemble(lines) do
    lines
    |> Enum.reduce({"", 0}, fn line, {acc, idx} ->
      sep = if idx > 0, do: "\n", else: ""
      {acc <> sep <> line, idx + 1}
    end)
    |> elem(0)
  end
end
