defmodule El.Pty.Size do
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
    if row > 0 and col > 0, do: {row, col}, else: {24, 80}
  rescue
    _ -> {24, 80}
  end
  defp extract(_), do: {24, 80}
end
