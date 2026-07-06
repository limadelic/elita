defmodule TraceIntegrationTest do
  use ExUnit.Case

  @tag :integration
  test "traces startup header and input with cat command" do
    trace_file = Path.join(System.tmp_dir!(), "trace_cat_#{System.unique_integer()}.log")
    System.put_env("EL_TRACE", trace_file)

    # Mock the input to send data and then close
    input_fn = fn data ->
      if byte_size(data) > 0 do
        data
      else
        :drop
      end
    end

    # Start pty with cat command
    {:ok, _pid} = El.Pty.start_link(
      :test_cat,
      "cat",
      cmd: "cat",
      get_size: fn -> {24, 80} end,
      input: input_fn
    )

    # Give it time to start and log header
    Process.sleep(200)

    # Send test input
    El.Pty.inject(:test_cat, "test123\r")

    # Give it time to log
    Process.sleep(100)

    # Check trace file
    assert File.exists?(trace_file), "Trace file should be created"
    content = File.read!(trace_file)
    lines = String.split(String.trim(content), "\n")

    # Verify header exists and has right format
    header = List.first(lines)
    assert String.contains?(header, "start"), "First line should be header with 'start'"
    assert String.contains?(header, "rows=24"), "Header should have rows=24"
    assert String.contains?(header, "cols=80"), "Header should have cols=80"

    # Verify input data is traced (test123 hex = 74657374313233)
    all_content = Enum.join(lines, " ")
    assert String.contains?(all_content, "74657374313233"), "Input should be traced in hex"

    # Cleanup
    El.Pty.inject(:test_cat, "\004")
    Process.sleep(100)
    System.delete_env("EL_TRACE")
    if File.exists?(trace_file), do: File.rm(trace_file)
  end
end
