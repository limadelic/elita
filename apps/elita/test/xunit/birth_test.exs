defmodule BirthTest do
  use Tester
  @moduletag :xunit

  test "mother births a baby" do
    spawn(:mother)
    ask(:mother, "it's time to give birth")
    verify("cry", ask(:baby, "spank"))
  end
end
