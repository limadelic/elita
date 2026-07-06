defmodule DistributionTest do
  use ExUnit.Case

  test "start returns :ok when Node.start succeeds" do
    # Mock successful node start
    assert El.Distribution.start() == :ok
  end

  test "start returns :ok even if already running" do
    # If node is already started, should still succeed
    assert El.Distribution.start() == :ok
  end

  test "cookie is set to :elita" do
    El.Distribution.start()
    assert Node.get_cookie() == :elita
  end
end
