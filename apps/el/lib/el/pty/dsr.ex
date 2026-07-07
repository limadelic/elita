defmodule El.Pty.Dsr do
  @moduledoc false

  def scan(data, rows, cols, buffer \\ ""), do: query(buffer <> data, rows, cols)

  defp query(chunk, rows, cols) do
    dsr(String.split(chunk, "\e[6n", parts: 2), chunk, rows, cols)
  end

  defp dsr([before, rest], _, rows, cols), do: {"\e[#{rows};#{cols}R", before <> rest}
  defp dsr(_, chunk, _, _), do: da(String.split(chunk, "\e[c", parts: 2), chunk)

  defp da([before, rest], _), do: {"\e[?6c", before <> rest}
  defp da(_, chunk), do: {"", chunk}
end
