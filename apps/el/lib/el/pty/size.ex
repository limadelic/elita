defmodule El.Pty.Size do
  @moduledoc false

  import System
  import String

  def get_default do
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
    size_or_default(num(rows), num(cols))
  rescue
    _ -> {24, 80}
  end

  defp extract(_), do: {24, 80}

  defp num(str), do: to_integer(str)

  defp size_or_default(row, col) when row > 0, do: check_col(col, row)
  defp size_or_default(_, _), do: {24, 80}

  defp check_col(col, row) when col > 0, do: {row, col}
  defp check_col(_, _), do: {24, 80}
end
