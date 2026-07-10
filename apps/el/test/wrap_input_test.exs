defmodule El.Wrap.InputTest do
  use ExUnit.Case

  describe "dispatch/2" do
    test "exits on /exit command" do
      parent = self()
      El.Wrap.Input.dispatch("/exit", parent)
      assert_received :exit_wrap
    end

    test "ignores empty lines" do
      El.Wrap.Input.dispatch("", self())
      refute_received :exit_wrap
    end

    test "returns ok for normal input" do
      assert El.Wrap.Input.dispatch("normal input", self()) == :ok
    end
  end
end
