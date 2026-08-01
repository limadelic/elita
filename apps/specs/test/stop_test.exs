defmodule StopTest do
  use SpecHelper

  test "stop through el entry point exercises stop trace" do
    spawn(:greet)

    before_ls = El.Commands.Ls.remote()
    assert before_ls =~ "greet session"

    output = ExUnit.CaptureIO.capture_io(fn ->
      El.Commands.Stop.stop("greet")
    end)

    assert output =~ "session greet not found"

    after_ls = El.Commands.Ls.remote()
    assert after_ls =~ "greet session"
  end
end
