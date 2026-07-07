defmodule El.TraceTest do
  use ExUnit.Case, async: false

  setup do
    trace_file = Path.join(System.tmp_dir!(), "test_trace_#{System.unique_integer()}.log")
    System.put_env("EL_TRACE", trace_file)

    on_exit(fn ->
      System.delete_env("EL_TRACE")
      if File.exists?(trace_file), do: File.rm(trace_file)
    end)

    {:ok, trace_file: trace_file}
  end

  test "logs chunks when EL_TRACE is set", %{trace_file: trace_file} do
    El.Trace.log_chunk("test input")

    assert File.exists?(trace_file)
    content = File.read!(trace_file)
    assert String.contains?(content, "test input")
  end

  test "logs with timestamp in milliseconds", %{trace_file: trace_file} do
    before = System.monotonic_time(:millisecond)
    El.Trace.log_chunk("data")
    after_log = System.monotonic_time(:millisecond)

    content = File.read!(trace_file)
    lines = String.split(String.trim(content), "\n")

    Enum.each(lines, fn line ->
      [timestamp_str | _] = String.split(line, " ", parts: 2)
      timestamp = String.to_integer(timestamp_str)
      assert timestamp >= before and timestamp <= after_log
    end)
  end

  test "logs hex representation", %{trace_file: trace_file} do
    El.Trace.log_chunk("AB")

    content = File.read!(trace_file)
    assert String.contains?(content, "4142")
  end

  test "logs ascii representation", %{trace_file: trace_file} do
    El.Trace.log_chunk("hello")

    content = File.read!(trace_file)
    assert String.contains?(content, "hello")
  end

  test "silent when EL_TRACE not set" do
    System.delete_env("EL_TRACE")
    trace_file = Path.join(System.tmp_dir!(), "no_trace.log")

    El.Trace.log_chunk("data")

    assert !File.exists?(trace_file)
  end

  test "appends to existing trace file", %{trace_file: trace_file} do
    El.Trace.log_chunk("first")
    El.Trace.log_chunk("second")

    content = File.read!(trace_file)
    lines = String.split(String.trim(content), "\n")
    assert length(lines) == 2
  end

  test "logs header at startup with size and tty source", %{trace_file: trace_file} do
    El.Trace.log_header({24, 80}, :tty)

    content = File.read!(trace_file)
    assert String.contains?(content, "start")
    assert String.contains?(content, "24")
    assert String.contains?(content, "80")
    assert String.contains?(content, "tty")
  end

  test "logs header with fallback tty source", %{trace_file: trace_file} do
    El.Trace.log_header({42, 100}, :user)

    content = File.read!(trace_file)
    assert String.contains?(content, "start")
    assert String.contains?(content, "user")
  end

  test "logs eof event", %{trace_file: trace_file} do
    El.Trace.log_event("stdin_eof")

    content = File.read!(trace_file)
    assert String.contains?(content, "stdin_eof")
  end

  test "logs error event with reason", %{trace_file: trace_file} do
    El.Trace.log_event("stdin_error", "eio")

    content = File.read!(trace_file)
    assert String.contains?(content, "stdin_error")
    assert String.contains?(content, "eio")
  end
end
