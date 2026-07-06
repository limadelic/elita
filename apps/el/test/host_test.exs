defmodule El.HostTest do
  use ExUnit.Case

  test "default host is 127.0.0.1" do
    assert El.Host.host(env_module: El.HostTest.FakeEnv) == "127.0.0.1"
  end

  test "reads EL_HOST from environment" do
    assert El.Host.host(env_module: El.HostTest.FakeEnvWithHost) == "home.local"
  end

  test "naming_mode for IP address returns :longnames" do
    assert El.Host.naming_mode("127.0.0.1") == :longnames
  end

  test "naming_mode for hostname with dot returns :longnames" do
    assert El.Host.naming_mode("home.local") == :longnames
  end

  test "naming_mode for hostname without dot returns :shortnames" do
    assert El.Host.naming_mode("localhost") == :shortnames
  end

  defmodule FakeEnv do
    def get(_key), do: nil
  end

  defmodule FakeEnvWithHost do
    def get("EL_HOST"), do: "home.local"
    def get(_key), do: nil
  end
end
