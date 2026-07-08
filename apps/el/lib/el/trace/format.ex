defmodule El.Trace.Format do
  @moduledoc false

  import :binary, only: [bin_to_list: 1]
  import System
  import String, only: [pad_leading: 3]
  import Enum
  import Integer, only: [to_string: 2]

  def trace(data) do
    timestamp = monotonic_time(:millisecond)
    hex = hex_data(data)
    ascii = ascii_data(data)
    "#{timestamp} #{hex} #{ascii}\n"
  end

  defp hex_data(data) do
    data
    |> bin_to_list()
    |> map_join("", &hex_byte/1)
  end

  defp hex_byte(byte) do
    byte
    |> to_string(16)
    |> pad_leading(2, "0")
  end

  defp ascii_data(data) do
    bin_to_list(data) |> map_join("", &safe_char/1)
  end

  defp safe_char(byte) when byte in 32..126, do: <<byte>>
  defp safe_char(_), do: "."
end
