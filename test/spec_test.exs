defmodule SpecTest do
  use Tester, async: true

  test "tell spec" do
    speck("tell")
  end

  test "agent spec" do
    speck("agent")
  end
end
