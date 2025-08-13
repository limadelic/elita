defmodule BirthTest do
  use ElitaTester

  setup do
    spawn(:mother)
    :ok
  end

  test "mother gives birth to baby" do
    ask(:mother, "it's time to give birth")

    verify(:baby, "WAAAAAH", "spank")
  end
end
