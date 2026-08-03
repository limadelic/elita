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

# Scratchpad directory for instrumentation log
scratchpad = "/private/tmp/claude-501/-Users-mike-dev-self-elita-donny/9abaf0ae-1d76-48bb-9076-60dd3e434da7/scratchpad"
File.mkdir_p(scratchpad)
log_file = Path.join(scratchpad, "door_instrumentation.log")
File.write(log_file, "")

# Source ~/.env to get ANTHROPIC_API_KEY
{env_output, _} = System.cmd("bash", ["-c", "source ~/.env && echo $elita"])
elita_key = String.trim(env_output)

unless elita_key != "" do
  IO.puts("ANTHROPIC_API_KEY not found in ~/.env, cannot proceed")
  System.halt(1)
end

System.put_env("ANTHROPIC_API_KEY", elita_key)

defmodule Watcher do
  def log(file, msg) do
    timestamp = System.monotonic_time(:millisecond)
    line = "#{timestamp} | #{msg}\n"
    File.write(file, line, [:append])
    IO.write(line)
  end

  def wait_for_banner(pty_pid, timeout_ms) do
    start = System.monotonic_time(:millisecond)
    wait_banner_loop(pty_pid, start, timeout_ms)
  end

  defp wait_banner_loop(pty_pid, start, timeout_ms) do
    elapsed = System.monotonic_time(:millisecond) - start
    if elapsed > timeout_ms do
      {:error, :banner_timeout}
    else
      state = :sys.get_state(pty_pid)
      # Wait for BOTH: banner in chunks AND idle=true in state
      recorder_pid = state[:recorder]
      idle = state[:idle]
      if recorder_pid && idle === true do
        record_state = Matrix.Movie.Record.get(recorder_pid)
        chunks = record_state.chunks
        # Chunks store raw binary data, not base64
        if Enum.any?(chunks, fn ch -> String.contains?(ch.chunk, "bypass permissions") end) do
          {:ok, chunks}
        else
          Process.sleep(100)
          wait_banner_loop(pty_pid, start, timeout_ms)
        end
      else
        Process.sleep(100)
        wait_banner_loop(pty_pid, start, timeout_ms)
      end
    end
  end

  def wait_for_prompt(pty_pid, agent_name, timeout_ms) do
    start = System.monotonic_time(:millisecond)
    prompt_pattern = "#{agent_name}> "
    wait_prompt_loop(pty_pid, prompt_pattern, start, timeout_ms)
  end

  defp wait_prompt_loop(pty_pid, prompt_pattern, start, timeout_ms) do
    elapsed = System.monotonic_time(:millisecond) - start
    if elapsed > timeout_ms do
      {:error, :prompt_timeout}
    else
      state = :sys.get_state(pty_pid)
      recorder_pid = state.recorder
      if recorder_pid do
        record_state = Matrix.Movie.Record.get(recorder_pid)
        chunks = record_state.chunks
        all_data = Enum.map_join(chunks, fn ch -> ch.chunk end)
        if String.contains?(all_data, prompt_pattern) do
          {:ok, length(chunks)}
        else
          Process.sleep(100)
          wait_prompt_loop(pty_pid, prompt_pattern, start, timeout_ms)
        end
      else
        Process.sleep(100)
        wait_prompt_loop(pty_pid, prompt_pattern, start, timeout_ms)
      end
    end
  end

  def wait_for_answer(pty_pid, timeout_ms) do
    start = System.monotonic_time(:millisecond)
    last_chunk_count = 0
    quiet_since = System.monotonic_time(:millisecond)
    answer_loop(pty_pid, start, timeout_ms, last_chunk_count, quiet_since)
  end

  defp answer_loop(pty_pid, start, timeout_ms, last_chunk_count, quiet_since) do
    elapsed = System.monotonic_time(:millisecond) - start
    quiet_elapsed = System.monotonic_time(:millisecond) - quiet_since

    # End if: overall timeout OR quiet for 3 seconds (chunks stopped arriving)
    if elapsed > timeout_ms do
      {:timeout, "Answer wait timed out after #{elapsed}ms"}
    else
      state = :sys.get_state(pty_pid)
      recorder_pid = state.recorder
      if recorder_pid do
        record_state = Matrix.Movie.Record.get(recorder_pid)
        chunks = record_state.chunks
        current_chunk_count = length(chunks)

        if current_chunk_count > last_chunk_count do
          # Chunks arriving, reset quiet timer
          Process.sleep(100)
          answer_loop(pty_pid, start, timeout_ms, current_chunk_count, System.monotonic_time(:millisecond))
        else
          # No new chunks
          if quiet_elapsed > 3000 && current_chunk_count > 0 do
            # Been quiet for 3 seconds, consider answer complete
            {:ok, Enum.map_join(chunks, fn ch -> ch.chunk end)}
          else
            Process.sleep(100)
            answer_loop(pty_pid, start, timeout_ms, current_chunk_count, quiet_since)
          end
        end
      else
        Process.sleep(100)
        answer_loop(pty_pid, start, timeout_ms, last_chunk_count, quiet_since)
      end
    end
  end
end

# Use a fresh agent name for this recording
agent_name = "door_claude"
pty_name = String.to_atom(agent_name)

try do
  Watcher.log(log_file, "Starting door.exs")

  # Launch bare claude directly (claude --dangerously-skip-permissions)
  # This avoids the complexity of el's routing and just tests claude interaction
  # The recorder is set up automatically by Matrix.Pty when TAPE=rec
  cmd = "claude --dangerously-skip-permissions"
  Watcher.log(log_file, "Launching: #{cmd}")

  pty_pid = Matrix.Pty.launch(pty_name,
    cmd: cmd,
    get_size: fn -> {24, 80} end
  )
  Watcher.log(log_file, "PTY launched, pid: #{inspect(pty_pid)}")

  # Wait for claude banner to appear
  Watcher.log(log_file, "Waiting for 'bypass permissions' banner (60s timeout)...")
  case Watcher.wait_for_banner(pty_pid, 60_000) do
    {:ok, chunks} ->
      Watcher.log(log_file, "Banner found after #{length(chunks)} chunks")
    {:error, :banner_timeout} ->
      Watcher.log(log_file, "BANNER TIMEOUT - banner never appeared")
      state = :sys.get_state(pty_pid)
      recorder_pid = state.recorder
      if recorder_pid do
        record_state = Matrix.Movie.Record.get(recorder_pid)
        chunks = record_state.chunks
        Enum.each(chunks, fn ch ->
          Watcher.log(log_file, "Chunk #{ch.i}: #{inspect(ch.chunk, limit: 100)}")
        end)
      end
      System.halt(1)
  end

  # For bare claude, wait for the Input prompt (not REPL)
  Watcher.log(log_file, "Waiting for claude to be ready...")
  # For bare claude, wait a bit for it to be fully ready
  Process.sleep(500)

  # Log current state before send
  state_before = :sys.get_state(pty_pid)
  recorder_pid = state_before.recorder
  if recorder_pid do
    record_state = Matrix.Movie.Record.get(recorder_pid)
    chunks = record_state.chunks
    Watcher.log(log_file, "Chunks before send: #{length(chunks)}")
    Enum.each(chunks, fn ch ->
      Watcher.log(log_file, "  Chunk #{ch.i}: #{inspect(ch.chunk, limit: 100)}")
    end)
  end

  # Send the query with carriage return (for bare claude)
  Watcher.log(log_file, "Sending: '1 + 1\\r'")
  Matrix.Pty.inject(pty_name, "1 + 1\r")
  Watcher.log(log_file, "Query sent, waiting for answer (90s timeout)...")

  # Wait for claude's response with gap-based detection
  case Watcher.wait_for_answer(pty_pid, 90_000) do
    {:ok, all_data} ->
      Watcher.log(log_file, "ANSWER COMPLETE - Got #{byte_size(all_data)} bytes")

      # Log chunks with decoded content
      state = :sys.get_state(pty_pid)
      recorder_pid = state.recorder
      if recorder_pid do
        record_state = Matrix.Movie.Record.get(recorder_pid)
        chunks = record_state.chunks
        Watcher.log(log_file, "Total chunks: #{length(chunks)}")
        Enum.each(chunks, fn ch ->
          decoded = ch.chunk
          Watcher.log(log_file, "Chunk #{ch.i}: #{inspect(decoded, limit: 150)}")
        end)
      end

      # Verify we got echo and answer
      has_echo = String.contains?(all_data, "1 + 1")
      has_answer = String.contains?(all_data, ["2"])
      Watcher.log(log_file, "Verification: has_echo=#{has_echo}, has_answer=#{has_answer}")

    {:timeout, msg} ->
      Watcher.log(log_file, "ANSWER TIMEOUT - #{msg}")
      state = :sys.get_state(pty_pid)
      recorder_pid = state.recorder
      if recorder_pid do
        record_state = Matrix.Movie.Record.get(recorder_pid)
        chunks = record_state.chunks
        all_data = Enum.map_join(chunks, fn ch -> ch.chunk end)
        has_echo = String.contains?(all_data, "1 + 1")
        Watcher.log(log_file, "Total chunks collected: #{length(chunks)}")
        Watcher.log(log_file, "Total data size: #{byte_size(all_data)}")
        Watcher.log(log_file, "Has echo: #{has_echo}")
        Enum.each(chunks, fn ch ->
          Watcher.log(log_file, "Chunk #{ch.i}: #{inspect(ch.chunk, limit: 150)}")
        end)
      end
  end

  # Send Ctrl+D to close
  Watcher.log(log_file, "Sending Ctrl+D")
  Matrix.Pty.inject(pty_name, "\x04")
  Process.sleep(1000)

  # Get the recorder from PTY state and flush it explicitly
  Watcher.log(log_file, "Flushing reel explicitly...")
  state = :sys.get_state(pty_pid)
  recorder_pid = state.recorder
  if recorder_pid do
    Matrix.Movie.Record.done(recorder_pid)
    Watcher.log(log_file, "Reel flushed via Record.done")
  else
    Watcher.log(log_file, "No recorder found")
  end

  # OTP teardown
  Watcher.log(log_file, "Starting OTP teardown...")
  port_ref = :erlang.monitor(:port, state.pty)
  :erlang.port_close(state.pty)
  Watcher.log(log_file, "Port closed, waiting for DOWN...")

  receive do
    {:DOWN, ^port_ref, :port, _port, _reason} ->
      Watcher.log(log_file, "Port closed successfully")
  after
    8_000 ->
      Watcher.log(log_file, "Timeout waiting for port close")
  end

  Watcher.log(log_file, "Teardown complete")
  System.halt(0)
rescue
  e ->
    Watcher.log(log_file, "Error: #{inspect(e)}")
    Watcher.log(log_file, Exception.format_stacktrace(__STACKTRACE__))
    System.halt(1)
end
