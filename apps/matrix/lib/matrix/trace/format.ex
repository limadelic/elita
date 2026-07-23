defmodule Matrix.Trace.Format do
  @moduledoc false

  import System
  import String, only: [pad_leading: 3]
  import Enum
  import Integer, only: [to_string: 2]

  def trace(data) do
    timestamp = monotonic_time(:millisecond)
    hex = hex(data)
    ascii = ascii(data)
    "#{timestamp} #{hex} #{ascii}\n"
  end

  defp hex(data) do
    bytes(data) |> map_join("", &encode/1)
  end

  defp encode(byte) do
    byte
    |> to_string(16)
    |> pad_leading(2, "0")
  end

  defp bytes(<<>>), do: []
  defp bytes(<<byte, rest::binary>>), do: [byte | bytes(rest)]

  defp ascii(data) do
    bytes(data) |> map_join("", &safe/1)
  end

  defp safe(byte) when byte in 32..126, do: <<byte>>
  defp safe(_), do: "."
end
