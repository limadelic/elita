defmodule El.Trace do
  @moduledoc false

  def log_chunk(data) do
    case System.get_env("EL_TRACE") do
      nil -> :ok
      path -> write_trace(path, data)
    end
  end

  def log_header(size, tty_source) do
    case System.get_env("EL_TRACE") do
      nil -> :ok
      path -> write_header(path, size, tty_source)
    end
  end

  def log_event(event) do
    case System.get_env("EL_TRACE") do
      nil -> :ok
      path -> write_event(path, event)
    end
  end

  def log_event(event, reason) do
    case System.get_env("EL_TRACE") do
      nil -> :ok
      path -> write_event(path, event, reason)
    end
  end

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
    timestamp = System.monotonic_time(:millisecond)
    hex = encode_hex(data)
    ascii = ascii_safe(data)
    line = "#{timestamp} #{hex} #{ascii}\n"

    File.write(path, line, [:append])
  end

  defp encode_hex(data) do
    data
    |> :binary.bin_to_list()
    |> Enum.map_join("", fn byte ->
      byte
      |> Integer.to_string(16)
      |> String.pad_leading(2, "0")
    end)
  end

  defp ascii_safe(data) do
    data
    |> String.to_charlist()
    |> Enum.map_join("", fn char ->
      if char >= 32 and char < 127, do: <<char>>, else: "."
    end)
  end
end
