defmodule BirthTest do
  use ExUnit.Case
  import Kernel, except: [spawn: 1, spawn: 2]
  import ElitaTester

  setup do
    spawn(:mother)
    :ok
  end

  test "mother gives birth to baby" do
    ask(:mother, "it's time to give birth")

    verify(:baby, "WAAAAAH", "spank")
  end
end
