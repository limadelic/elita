defmodule BirthTest do
  use ExUnit.Case
  import ElitaTester

  setup do
    start(:mother)
    :ok
  end

  test "mother gives birth to baby" do
    ask(:mother, "it's time to give birth")

    verify(:baby, "WAAAAAH", "spank")
  end
end
