defmodule TellTest do
  use SpecHelper

  test "tell dispatches for local agent" do
    output = tell(:greet, "hello")

    assert is_binary(output)
  end

  test "tell to unknown agent silently succeeds" do
    output = tell(:unknown, "hello")

    assert output == ""
  end

  test "tell with @ syntax for remote agent" do
    output = tell("user@host", "hello")

    assert is_binary(output)
  end

  defp tell(agent, msg) do
    capture_io(fn -> El.Commands.Tell.send(agent, msg) end)
  end

  defp capture_io(fun) do
    ExUnit.CaptureIO.capture_io(fun)
  end
end
