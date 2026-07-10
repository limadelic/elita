defmodule El.DistributionTest do
  use ExUnit.Case

  describe "target/1" do
    test "returns nil when puppet not found" do
      assert El.Distribution.target("nonexistent") == nil
    end

    test "returns pid when puppet is registered" do
      # Register a fake puppet globally
      pid = spawn(fn -> :timer.sleep(:infinity) end)
      :global.register_name({"test_puppet", :puppet}, pid)

      assert El.Distribution.target("test_puppet") == pid

      # Cleanup
      :global.unregister_name({"test_puppet", :puppet})
      Process.exit(pid, :kill)
    end
  end
end
