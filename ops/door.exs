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

  def wait_for_answer(pty_pid, injected_text, timeout_ms) do
    start = System.monotonic_time(:millisecond)
    answer_loop(pty_pid, injected_text, start, timeout_ms, false)
  end

  defp answer_loop(pty_pid, _injected_text, start, timeout_ms, _seen_answer) do
    elapsed = System.monotonic_time(:millisecond) - start
    if elapsed > timeout_ms do
      {:timeout, "Answer wait timed out after #{elapsed}ms"}
    else
      state = :sys.get_state(pty_pid)
      recorder_pid = state.recorder
      if recorder_pid do
        record_state = Matrix.Movie.Record.get(recorder_pid)
        chunks = record_state.chunks
        # Chunks store raw binary data, not base64
        all_data = Enum.map_join(chunks, fn ch -> ch.chunk end)

        # Check if we have both the echo and the response
        has_echo = String.contains?(all_data, "1 + 1")

        # Simple heuristic: look for "2" or numeric answer
        has_answer = String.contains?(all_data, ["2", "result", "answer", "equals"])

        if has_echo and has_answer do
          {:ok, all_data}
        else
          Process.sleep(200)
          answer_loop(pty_pid, "", start, timeout_ms, has_answer)
        end
      else
        Process.sleep(200)
        answer_loop(pty_pid, "", start, timeout_ms, false)
      end
    end
  end
end

# Use a fresh agent name that's never appeared in epmd -names
agent_name = "doorman"
pty_name = String.to_atom(agent_name)

try do
  Watcher.log(log_file, "Starting door.exs")

  # Launch el claude with the fresh agent name
  # Recorder is set up automatically by Matrix.Pty when TAPE=rec
  el_escript = "/Users/mike/dev/self/elita/donny/apps/el/el"
  cmd = "#{el_escript} claude #{agent_name}"
  Watcher.log(log_file, "Launching: #{cmd}")

  pty_pid = Matrix.Pty.launch(
    pty_name,
    name: pty_name,
    cmd: cmd,
    get_size: fn -> {24, 80} end
  )
  Watcher.log(log_file, "PTY launched, pid: #{inspect(pty_pid)}")

  # Wait for claude to fully load and reach the banner
  Watcher.log(log_file, "Waiting for 'bypass permissions' banner (60s timeout)...")
  case Watcher.wait_for_banner(pty_pid, 60_000) do
    {:ok, chunks} ->
      Watcher.log(log_file, "Banner found after #{length(chunks)} chunks")
      state = :sys.get_state(pty_pid)
      Watcher.log(log_file, "State after banner: idle=#{state[:idle]}, ready=#{state[:ready]}, buffer=#{inspect(state[:buffer])}, pending_msg=#{inspect(state[:pending_msg])}")
    {:error, :banner_timeout} ->
      Watcher.log(log_file, "BANNER TIMEOUT - banner never appeared")
      state = :sys.get_state(pty_pid)
      recorder_pid = state.recorder
      if recorder_pid do
        record_state = Matrix.Movie.Record.get(recorder_pid)
        chunks = record_state.chunks
        Enum.each(chunks, fn ch ->
          # Chunks store raw binary data
          Watcher.log(log_file, "Chunk #{ch.i}: #{inspect(ch.chunk, limit: 100)}")
        end)
      end
      System.halt(1)
  end

  # Inject the math query - try char-by-char with delay to trigger echo
  Watcher.log(log_file, "Injecting: '1 + 1' char-by-char")
  state_before = :sys.get_state(pty_pid)
  Watcher.log(log_file, "State before inject: idle=#{state_before[:idle]}")

  # Send char by char with delays to trigger terminal echo
  String.graphemes("1 + 1")
  |> Enum.each(fn char ->
    Matrix.Pty.inject(pty_name, char)
    Process.sleep(50)
  end)

  Process.sleep(500)
  state_after = :sys.get_state(pty_pid)
  Watcher.log(log_file, "State after inject: idle=#{state_after[:idle]}, buffer=#{inspect(state_after[:buffer])}, pending_msg=#{inspect(state_after[:pending_msg])}")

  # Now send carriage return to submit
  Watcher.log(log_file, "Sending \\r to submit")
  Matrix.Pty.inject(pty_name, "\r")

  # Wait for claude's response (90s timeout for thinking and streaming)
  Watcher.log(log_file, "Waiting for answer (90s timeout)...")
  case Watcher.wait_for_answer(pty_pid, "1 + 1", 90_000) do
    {:ok, all_data} ->
      Watcher.log(log_file, "ANSWER RECEIVED - session has echo and response")
      # Log last 500 chars of data
      tail = String.slice(all_data, -500..-1)
      Watcher.log(log_file, "Last 500 chars: #{inspect(tail)}")
    {:timeout, msg} ->
      Watcher.log(log_file, "ANSWER TIMEOUT - #{msg}")
      state = :sys.get_state(pty_pid)
      recorder_pid = state.recorder
      if recorder_pid do
        record_state = Matrix.Movie.Record.get(recorder_pid)
        chunks = record_state.chunks
        # Chunks store raw binary data
        all_data = Enum.map_join(chunks, fn ch -> ch.chunk end)
        has_echo = String.contains?(all_data, "1 + 1")
        has_carriage_return = String.contains?(all_data, "\r")
        Watcher.log(log_file, "Has '1 + 1' echo: #{has_echo}")
        Watcher.log(log_file, "Has carriage return: #{has_carriage_return}")
        Watcher.log(log_file, "Total chunks: #{length(chunks)}")
        Watcher.log(log_file, "Total data size: #{byte_size(all_data)}")
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
