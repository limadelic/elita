defmodule Matrix.Pty.Size do
  @moduledoc false

  import System
  import String

  def default do
    cmd("sh", ["-c", "stty size < /dev/tty"], stderr_to_stdout: true)
    |> parse()
  rescue
    _ -> {24, 80}
  end

  defp parse({output, 0}) do
    output |> trim() |> split() |> extract()
  end

  defp parse(_), do: {24, 80}

  defp extract([rows, cols]) do
    verify(num(rows), num(cols))
  rescue
    _ -> {24, 80}
  end

  defp extract(_), do: {24, 80}

  defp num(str), do: to_integer(str)

  defp verify(row, col) when row > 0, do: pair(col, row)
  defp verify(_, _), do: {24, 80}

  defp pair(col, row) when col > 0, do: {row, col}
  defp pair(_, _), do: {24, 80}
end
