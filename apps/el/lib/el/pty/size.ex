defmodule El.Pty.Size do
  @moduledoc false

  def get_default do
    System.cmd("sh", ["-c", "stty size < /dev/tty"], stderr_to_stdout: true)
    |> parse()
  rescue
    _ -> {24, 80}
  end

  defp parse({output, 0}) do
    output |> String.trim() |> String.split() |> extract()
  end
  defp parse(_), do: {24, 80}

  defp extract([rows, cols]) do
    row = String.to_integer(rows)
    col = String.to_integer(cols)
    size_or_default(row, col)
  rescue
    _ -> {24, 80}
  end
  defp extract(_), do: {24, 80}

  defp size_or_default(row, col) do
    pick_size(row > 0 and col > 0, row, col)
  end

  defp pick_size(true, row, col), do: {row, col}
  defp pick_size(false, _, _), do: {24, 80}
end
