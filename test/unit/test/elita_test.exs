defmodule ElitaTest do
  use ExUnit.Case

  test "elita agent module exists" do
    assert Code.ensure_loaded?(Elita.Agent)
  end
end
