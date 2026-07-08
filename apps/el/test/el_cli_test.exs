Code.require_file("../../elita/test/tester.exs", __DIR__)

defmodule ElCliTest do
  use Tester

  import ExUnit.CaptureIO

  setup do
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", "greet")

    spawn(:greet)

    on_exit(fn ->
      System.delete_env("TAPE")
      System.delete_env("CASSETTE")

      try do
        halt(:greet)
      rescue
        _ -> :ok
      catch
        :exit, _ -> :ok
      end
    end)

    :ok
  end

  test "el ask greet hello returns cassette reply" do
    output =
      capture_io(fn ->
        El.CLI.main(["ask", "greet", "hello"])
      end)

    assert String.contains?(output, "Who am I talking to")
  end

  test "el ask unknown agent returns error immediately" do
    output =
      capture_io(fn ->
        El.CLI.main(["ask", "garbage_xyz", "hello"])
      end)

    assert String.contains?(output, "unknown: garbage_xyz")
  end
end
