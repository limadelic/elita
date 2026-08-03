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

Application.start(:logger)
Application.start(:matrix)
Application.start(:tape)

# Use a fresh agent name that's never appeared in epmd -names
agent_name = "witness"
pty_name = String.to_atom(agent_name)

try do
  # Launch el claude with the fresh agent name
  # Recorder is set up automatically by Matrix.Pty when TAPE=rec
  cmd = "el claude #{agent_name}"
  IO.puts("Launching: #{cmd}")

  pty_pid = Matrix.Pty.launch(
    pty_name,
    name: pty_name,
    cmd: cmd,
    get_size: fn -> {24, 80} end
  )
  IO.puts("PTY launched, pid: #{inspect(pty_pid)}")

  # Wait for claude to fully load
  IO.puts("Waiting for permissions bypass banner...")
  Process.sleep(5000)

  # Inject the math query (NO \r - Buffer.submit sends it after echo)
  IO.puts("Injecting: 1 + 1")
  Matrix.Pty.inject(pty_name, "1 + 1")

  # Wait for claude's response
  IO.puts("Waiting for response...")
  Process.sleep(6000)

  # Send Ctrl+D to close
  IO.puts("Sending Ctrl+D")
  Matrix.Pty.inject(pty_name, "\x04")
  Process.sleep(1000)

  # Get the recorder from PTY state and flush it explicitly
  IO.puts("Flushing reel explicitly...")
  state = :sys.get_state(pty_pid)
  recorder_pid = state.recorder
  if recorder_pid do
    Matrix.Movie.Record.done(recorder_pid)
    IO.puts("Reel flushed via Record.done")
  else
    IO.puts("No recorder found")
  end

  # OTP teardown
  IO.puts("Starting OTP teardown...")
  port_ref = :erlang.monitor(:port, state.pty)
  :erlang.port_close(state.pty)
  IO.puts("Port closed, waiting for down...")

  receive do
    {:DOWN, ^port_ref, :port, _port, _reason} ->
      IO.puts("Port closed successfully")
  after
    8_000 ->
      IO.puts("Timeout waiting for port close")
  end

  IO.puts("Teardown complete")
  System.halt(0)
rescue
  e ->
    IO.puts("Error: #{inspect(e)}")
    IO.puts(Exception.format_stacktrace(__STACKTRACE__))
    System.halt(1)
end
