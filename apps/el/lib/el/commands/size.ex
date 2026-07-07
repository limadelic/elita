defmodule El.Commands.Size do
  @moduledoc false

  def read_terminal_size, do: fallback([read_env(), read_stty(), {24, 80}])

  defp fallback([nil | rest]), do: fallback(rest)
  defp fallback([size | _]), do: size

  defp read_env do
    {safe_int(System.get_env("EL_ROWS")), safe_int(System.get_env("EL_COLS"))}
    |> check_valid()
  end

  defp check_valid({row, col}) do
    pick_valid({row > 0, col > 0, row, col})
  end

  defp pick_valid({true, true, row, col}), do: {row, col}
  defp pick_valid({_, _, _, _}), do: nil

  defp safe_int(str) when is_binary(str) do
    String.to_integer(str)
  rescue
    _ -> 0
  end

  defp safe_int(_), do: 0

  defp read_stty do
    System.cmd("sh", ["-c", "stty size < /dev/tty"], stderr_to_stdout: true)
    |> parse_stty()
  rescue
    _ -> nil
  end

  defp parse_stty({output, 0}) do
    String.trim(output) |> String.split() |> extract_pair()
  end

  defp parse_stty(_), do: nil

  defp extract_pair([row_str, col_str]) do
    {safe_int(row_str), safe_int(col_str)}
    |> check_valid()
  end

  defp extract_pair(_), do: nil
end
