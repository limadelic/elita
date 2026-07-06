defmodule El.Trace do
  def log_chunk(data) do
    case System.get_env("EL_TRACE") do
      nil -> :ok
      path -> write_trace(path, data)
    end
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
    |> Enum.map(&Integer.to_string(&1, 16))
    |> Enum.map(&String.pad_leading(&1, 2, "0"))
    |> Enum.join("")
  end

  defp ascii_safe(data) do
    data
    |> String.to_charlist()
    |> Enum.map(fn char ->
      if char >= 32 and char < 127, do: <<char>>, else: "."
    end)
    |> Enum.join("")
  end
end
