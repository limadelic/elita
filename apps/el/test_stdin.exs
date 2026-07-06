#!/usr/bin/env elixir

# Quick test: can we read from /dev/stdin?
case File.open("/dev/stdin", [:read, :binary, :raw]) do
  {:ok, stdin} ->
    IO.puts("STDIN OPENED: #{inspect(stdin)}")

    # Try to read one byte
    case File.read(stdin, 1) do
      {:ok, data} ->
        IO.puts("READ: #{inspect(data)} (hex: #{Base.encode16(data)})")
      err ->
        IO.puts("READ ERROR: #{inspect(err)}")
    end

    File.close(stdin)

  {:error, reason} ->
    IO.puts("OPEN ERROR: #{inspect(reason)}")
end
