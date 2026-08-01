defmodule LsTest do
  use SpecHelper

  test "ls command exercises ls module" do
    spawn(:greet)

    output = ExUnit.CaptureIO.capture_io(fn -> El.Commands.Ls.ls() end)

    assert is_binary(output)
    assert String.length(output) > 0
  end

  test "ls remote with path" do
    result = El.Commands.Ls.remote(path: "//")

    assert is_binary(result)
  end
end
