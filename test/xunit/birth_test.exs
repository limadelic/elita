defmodule BirthTest do
  use Tester

  setup do
    spawn(:mother)
    :ok
  end

  test "mother gives birth to baby" do
    ask(:mother, "it's time to give birth")

    verify(:baby, "cries", "spank")
  end
end
