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

    test "returns ok for normal input" do
      assert El.Wrap.Input.dispatch("normal input", self(), :agent) == :ok
    end

    test "returns ok for input without puppet match" do
      assert El.Wrap.Input.dispatch("unknown knock knock", self(), :agent) == :ok
    end

    test "routes to puppet when first word matches" do
      parent = self()
      agent = :malko

      # Register a mock puppet
      pid = spawn(fn ->
        receive do
          {:ask, msg} -> send(parent, {:puppet_msg, msg})
        end
      end)
      :global.register_name({:malkovich, :puppet}, pid)

      # This should route to the puppet
      El.Wrap.Input.dispatch("malkovich knock knock", parent, agent)

      # Cleanup
      :global.unregister_name({:malkovich, :puppet})
      Process.exit(pid, :kill)
    end
  end
end
