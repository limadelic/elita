defmodule ElCliTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", "greet")

    on_exit(fn ->
      System.delete_env("TAPE")
      System.delete_env("CASSETTE")
    end)

    :ok
  end

  test "el ask greet hello returns cassette reply" do
    output = capture_io(fn ->
      El.CLI.main(["ask", "greet", "hello"])
    end)

    assert String.contains?(output, "Who am I talking to")
  end

  test "el ls returns no sessions or list" do
    output = capture_io(fn ->
      El.CLI.main(["ls"])
    end)

    assert String.contains?(output, "sessions") or String.contains?(output, "claude_")
  end
end
