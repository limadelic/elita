defmodule AddressTest do
  use SpecHelper

  test "address handles unknown recipient" do
    assert ask("@nosuchagent", "hello") =~ ~r/^unknown: @nosuchagent$/
  end
end
