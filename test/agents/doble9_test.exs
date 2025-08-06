defmodule Doble9Test do
  use ExUnit.Case
  import ElitaTester

  setup do
    start :doble9
    :ok
  end

  test "fresh shuffle dominoes on start" do
    verify :doble9, "ready", "start a new game"
  end
end