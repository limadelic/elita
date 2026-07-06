defmodule El.Trace do
  @moduledoc false

  import :binary, only: [bin_to_list: 1]

  def log_chunk(data) do
    log_chunk_maybe(System.get_env("EL_TRACE"), data)
  end

  defp log_chunk_maybe(nil, _data), do: :ok
  defp log_chunk_maybe(path, data), do: write_trace(path, data)

  def log_header(size, tty_source) do
    log_header_maybe(System.get_env("EL_TRACE"), size, tty_source)
  end

  defp log_header_maybe(nil, _size, _tty_source), do: :ok
  defp log_header_maybe(path, size, tty_source), do: write_header(path, size, tty_source)

  def log_event(event) do
    log_event_maybe(System.get_env("EL_TRACE"), event)
  end

  defp log_event_maybe(nil, _event), do: :ok
  defp log_event_maybe(path, event), do: write_event(path, event)

  def log_event(event, reason) do
    log_event_maybe(System.get_env("EL_TRACE"), event, reason)
  end

  defp log_event_maybe(nil, _event, _reason), do: :ok
  defp log_event_maybe(path, event, reason), do: write_event(path, event, reason)

  defp write_header(path, {rows, cols}, tty_source) do
    timestamp = System.monotonic_time(:millisecond)
    line = "#{timestamp} start rows=#{rows} cols=#{cols} tty_source=#{tty_source}\n"
    File.write(path, line, [:append])
  end

  defp write_event(path, event) do
    timestamp = System.monotonic_time(:millisecond)
    line = "#{timestamp} #{event}\n"
    File.write(path, line, [:append])
  end

  defp write_event(path, event, reason) do
    timestamp = System.monotonic_time(:millisecond)
    line = "#{timestamp} #{event} reason=#{reason}\n"
    File.write(path, line, [:append])
  end

  defp write_trace(path, data) do
    line = format_trace(data)
    File.write(path, line, [:append])
  end

  defp format_trace(data) do
    timestamp = System.monotonic_time(:millisecond)
    hex = encode_hex(data)
    ascii = ascii_safe(data)
    "#{timestamp} #{hex} #{ascii}\n"
  end

  defp encode_hex(data) do
    data
    |> bin_to_list()
    |> Enum.map_join("", &hex_byte/1)
  end

  defp hex_byte(byte) do
    byte
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end

  defp ascii_safe(data) do
    data
    |> String.to_charlist()
    |> Enum.map_join("", &safe_char/1)
  end

  defp safe_char(char) do
    {char in 32..126, char} |> format_char()
  end

  defp format_char({true, char}), do: <<char>>
  defp format_char({false, _}), do: "."
end
