defmodule ApiTest do
  use ExUnit.Case
  doctest Api

  test "API module exists" do
    assert Code.ensure_loaded?(Api)
  end
end
