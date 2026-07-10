defmodule El.Commands.Size do
  @moduledoc false

  import System
  import String

  def size, do: fallback([env(), stty(), {24, 80}])

  defp fallback([nil | rest]), do: fallback(rest)
  defp fallback([size | _]), do: size

  defp env do
    {int(get_env("EL_ROWS")), int(get_env("EL_COLS"))}
    |> validate()
  end

  defp validate({row, col}) do
    pick({row > 0, col > 0, row, col})
  end

  defp pick({true, true, row, col}), do: {row, col}
  defp pick({_, _, _, _}), do: nil

  defp int(str) when is_binary(str) do
    to_integer(str)
  rescue
    _ -> 0
  end

  defp int(_), do: 0

  defp stty do
    cmd("sh", ["-c", "stty size < /dev/tty"], stderr_to_stdout: true)
    |> parse()
  rescue
    _ -> nil
  end

  defp parse({output, 0}) do
    trim(output) |> split() |> pair()
  end

  defp parse(_), do: nil

  defp pair([row_str, col_str]) do
    {int(row_str), int(col_str)}
    |> validate()
  end

  defp pair(_), do: nil
end
