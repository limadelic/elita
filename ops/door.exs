#!/usr/bin/env elixir
# Film a door session via Matrix.Pty recording

if System.get_env("TAPE") != "rec" do
  IO.puts("rec mode required")
  System.halt(0)
end

System.put_env("CASSETTE_DIR", Path.expand("../features/cassettes", __DIR__))
System.put_env("CASSETTE", "door")

# Start tape and matrix apps (elita depends on matrix)
Application.start(:logger)
Application.start(:matrix)
Application.start(:tape)
Application.start(:elita)

# Boot and run the pty
try do
  # Create a temp file with input commands
  input_file = "/tmp/door_input_#{System.unique_integer()}.txt"
  File.write!(input_file, "1 + 1\n/exit\n")

  pid = Matrix.Pty.launch(
    :malko,
    cmd: "cat #{input_file} | el claude malko"
  )

  result = receive do
    {:DOWN, _ref, :process, ^pid, _reason} -> :ok
  after
    120_000 -> {:error, :timeout}
  end

  File.rm(input_file)

  case result do
    :ok -> System.halt(0)
    {:error, :timeout} -> System.halt(1)
  end
rescue
  e ->
    IO.puts("Error: #{inspect(e)}")
    System.halt(1)
end
