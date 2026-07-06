defmodule El.Pty.Dsr do
  @moduledoc false

  def scan(data, rows, cols, buffer \\ ""), do: extract_query(buffer <> data, rows, cols)

  defp extract_query(chunk, rows, cols) do
    extract_dsr(chunk, rows, cols) || extract_da(chunk)
  end

  defp extract_dsr(chunk, rows, cols) do
    case String.split(chunk, "\e[6n", parts: 2) do
      [before, rest] -> {"\e[#{rows};#{cols}R", before <> rest}
      _ -> nil
    end
  end

  defp extract_da(chunk) do
    case String.split(chunk, "\e[c", parts: 2) do
      [before, rest] -> {"\e[?6c", before <> rest}
      _ -> {"", chunk}
    end
  end
end
