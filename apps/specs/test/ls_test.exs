defmodule LsTest do
  use SpecHelper

  test "ls command exercises ls module" do
    spawn(:greet)

    output = ExUnit.CaptureIO.capture_io(fn -> El.Commands.Ls.ls() end)

    assert output =~ "greet"
    assert output =~ "session"
    assert output =~ "active"
    refute output == "no agents"
  end

  test "ls remote with path" do
    spawn(:greet)

    result = El.Commands.Ls.remote(path: "//")

    assert result =~ "node" or result == "no agents"
    refute result == "booting"
  end
end
