defmodule DistributionTest do
  use ExUnit.Case

  test "start returns :ok when Node.start succeeds" do
    assert El.Distribution.start() == :ok
  end

  test "start returns :ok even if already running" do
    assert El.Distribution.start() == :ok
  end

  test "cookie is set to :elita" do
    El.Distribution.start()
    assert Node.get_cookie() == :elita
  end

  test "uses :longnames for host with dot" do
    opts = [host: "home.local"]
    assert El.Distribution.naming_mode(opts) == :longnames
  end

  test "uses :shortnames for host without dot" do
    opts = [host: "localhost"]
    assert El.Distribution.naming_mode(opts) == :shortnames
  end

  test "uses default host 127.0.0.1" do
    opts = []
    assert El.Distribution.resolve_host(opts) == "127.0.0.1"
  end

  test "uses custom host from opts" do
    opts = [host: "home.local"]
    assert El.Distribution.resolve_host(opts) == "home.local"
  end
end
