defmodule BirthTest do
  use Tester
  @moduletag :xunit

  setup do
    spawn(:mother)
    :ok
  end

  test "mother gives birth to baby" do
    ask(:mother, "it's time to give birth")

    verify(:baby, "cry", "spank")
  end
end
