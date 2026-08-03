#!/usr/bin/env elixir
# Film a door session with real claude answering 1 + 1

if System.get_env("TAPE") != "rec" do
  IO.puts("rec mode required")
  System.halt(0)
end

cassette_dir = Path.expand("../features/cassettes", __DIR__)
cassette_file_base = "door"

System.put_env("CASSETTE_DIR", cassette_dir)
System.put_env("CASSETTE", cassette_file_base)

# Create empty cassette file if it doesn't exist (for the base "door" cassette)
cassette_file = Path.join(cassette_dir, "#{cassette_file_base}.json")
unless File.exists?(cassette_file) do
  File.write!(cassette_file, ~S({"movies":{}}))
end

Application.start(:logger)
Application.start(:matrix)
Application.start(:tape)

# Use a specific session name like door11, bump per retry
unique_suffix = System.get_env("DOOR_RETRY", "11")
unique_name = "door#{unique_suffix}"
pty_name = String.to_atom(unique_name)

try do
  # Launch claude as a simple calculator
  IO.puts("Launching pty: #{pty_name} with simple claude prompt")
  pid = Matrix.Pty.launch(
    pty_name,
    cmd: "claude --model haiku --dangerously-skip-permissions"
  )
  IO.puts("PTY launched, pid: #{inspect(pid)}")

  # Give claude time to start and show welcome
  IO.puts("Waiting for claude to start...")
  Process.sleep(3000)

  # Inject the math query (NO \r - buffer sends it after echo)
  IO.puts("Injecting: 1 + 1")
  Matrix.Pty.inject(pty_name, "1 + 1")
  IO.puts("Waiting for response...")
  Process.sleep(4000)

  # Inject Ctrl+D to close the connection
  IO.puts("Injecting: Ctrl+D")
  Matrix.Pty.inject(pty_name, "\x04")
  IO.puts("Waiting a bit more...")
  Process.sleep(2000)

  # Wait for PTY to close with a reasonable timeout
  IO.puts("Waiting for PTY to close...")

  receive do
    {:DOWN, _ref, :process, ^pid, _reason} ->
      IO.puts("PTY closed successfully")
      System.halt(0)
  after
    5_000 ->
      IO.puts("Timeout waiting for PTY to close, but data should be recorded")
      System.halt(0)
  end
rescue
  e ->
    IO.puts("Error: #{inspect(e)}")
    IO.puts(Exception.format_stacktrace(__STACKTRACE__))
    System.halt(1)
end
