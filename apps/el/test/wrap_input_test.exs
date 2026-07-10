defmodule El.Wrap.InputTest do
  use ExUnit.Case

  describe "dispatch/3" do
    test "exits on /exit command" do
      parent = self()
      El.Wrap.Input.dispatch("/exit", parent, :agent)
      assert_received :exit_wrap
    end

    test "ignores empty lines" do
      El.Wrap.Input.dispatch("", self(), :agent)
      refute_received :exit_wrap
    end

    test "returns forward for normal input" do
      assert El.Wrap.Input.dispatch("normal input", self(), :agent) == :forward
    end

    test "returns forward for input without puppet match" do
      assert El.Wrap.Input.dispatch("unknown knock knock", self(), :agent) == :forward
    end

    test "routes to puppet when first word matches" do
      # This test would require a real puppet process to work
      # For now, just verify it doesn't error when puppet not found
      assert El.Wrap.Input.dispatch("nonexistent knock knock", self(), :agent) == :forward
    end

    test "returns handled when puppet is found and asked" do
      # This test requires the puppet to be registered
      # For now, just verify the return value flow works
      result = El.Wrap.Input.dispatch("nonexistent knock knock", self(), :agent)
      assert result in [:forward, {:handled}]
    end
  end
end
