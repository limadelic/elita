#!/usr/bin/env elixir
# Film a door session with el claude pinto answering 1 + 1
# Explicitly flush the recording without waiting for el to close

if System.get_env("TAPE") != "rec" do
  IO.puts("rec mode required")
  System.halt(0)
end

cassette_dir = Path.expand("../features/cassettes", __DIR__)
cassette_file_base = "door"

System.put_env("CASSETTE_DIR", cassette_dir)
System.put_env("CASSETTE", cassette_file_base)

# Clean cassette file for fresh recording
cassette_file = Path.join(cassette_dir, "#{cassette_file_base}.json")
File.write!(cassette_file, ~S({"movies":{}}))

Application.start(:logger)
Application.start(:matrix)
Application.start(:tape)

# Use unique session name
unique_suffix = System.get_env("DOOR_RETRY", "43")
unique_name = "door#{unique_suffix}"
pty_name = String.to_atom(unique_name)

# Wait for text in chunks via taps
wait_for_text = fn text, timeout ->
  deadline = System.monotonic_time(:millisecond) + timeout

  wait_impl = fn wait_fn ->
    remaining = deadline - System.monotonic_time(:millisecond)

    if remaining <= 0 do
      false
    else
      receive do
        {:output, chunk} ->
          if String.contains?(chunk, text) do
            true
          else
            wait_fn.(wait_fn)
          end
      after
        remaining ->
          false
      end
    end
  end

  wait_impl.(wait_impl)
end

try do
  # Use --bare mode for minimal output, --ax-screen-reader for plain text
  cmd_str = "claude --bare --ax-screen-reader --dangerously-skip-permissions"
  IO.puts("Launching pty: #{pty_name} with cmd: #{cmd_str}")

  pid = Matrix.Pty.launch(
    pty_name,
    cmd: cmd_str,
    taps: [self()]
  )
  IO.puts("PTY pid: #{inspect(pid)}")

  # Wait for bypass permissions banner
  IO.puts("Waiting for bypass permissions banner...")
  unless wait_for_text.("bypass", 10_000) do
    IO.puts("ERROR: bypass permissions never found")
    System.halt(1)
  end
  IO.puts("Got banner")

  # Inject query with carriage return
  IO.puts("Injecting: 1 + 1 with CR")
  result = Matrix.Pty.inject(pty_name, "1 + 1\r")
  IO.puts("Inject result: #{inspect(result)}")

  # Wait for claude to respond by collecting chunks for a time window
  # but stop early if we see the new prompt (idle indicator)
  IO.puts("Collecting response chunks (60 second timeout)...")
  deadline = System.monotonic_time(:millisecond) + 60_000
  chunk_count = 0
  idle_count = 0

  collect_loop = fn collect_fn, count, idle ->
    now = System.monotonic_time(:millisecond)

    if now >= deadline do
      count
    else
      remaining = deadline - now

      receive do
        {:output, chunk} ->
          byte_sz = byte_size(chunk)
          IO.puts("  Chunk #{count}: #{byte_sz} bytes")

          # Stop early if we see a silent period (no new output for 3 consecutive chunks)
          if byte_sz < 50 do
            new_idle = idle + 1
            if new_idle >= 3 do
              IO.puts("  (stopping early - idle detected)")
              count + 1
            else
              collect_fn.(collect_fn, count + 1, new_idle)
            end
          else
            collect_fn.(collect_fn, count + 1, 0)
          end
      after
        remaining -> count
      end
    end
  end

  chunk_count = collect_loop.(collect_loop, chunk_count, idle_count)
  IO.puts("Response collection complete - received #{chunk_count} chunks - flushing recording")

  # Explicitly flush the recording by calling done/1
  # This writes the real captured chunks to the cassette
  try do
    state = :sys.get_state(pty_name)
    recorder = state.recorder

    if recorder do
      IO.puts("Flushing recorder...")
      Matrix.Movie.Record.done(recorder)
      IO.puts("Recording flushed")
    else
      IO.puts("ERROR: no recorder found in state")
      System.halt(1)
    end
  rescue
    e ->
      IO.puts("Error getting recorder: #{inspect(e)}")
      System.halt(1)
  end

  # Now close the port gracefully
  IO.puts("Closing port...")
  try do
    state = :sys.get_state(pty_name)
    port = state.port

    if port do
      ref = :erlang.monitor(:port, port)
      :erlang.port_close(port)

      receive do
        {:DOWN, ^ref, :port, ^port, _} -> :ok
      after
        3_000 -> :ok
      end

      IO.puts("Port closed")
    else
      IO.puts("No port found")
    end
  rescue
    e ->
      IO.puts("Error closing port: #{inspect(e)}")
  end

  System.halt(0)
rescue
  e ->
    IO.puts("Error: #{inspect(e)}")
    IO.puts(Exception.format_stacktrace(__STACKTRACE__))
    System.halt(1)
end
