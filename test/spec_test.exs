defmodule SpecTest do
  use Tester, async: true

  test "agent spec" do
    speck("agent")
  end

  test "mem spec" do
    speck("mem")
  end

  test "spawn spec" do
    speck("spawn")
  end

  test "tell spec" do
    speck("tell")
  end

end
