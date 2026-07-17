defmodule BirthTest do
  use Tester
  @moduletag :xunit

  test "mother births a baby" do
    spawn(:mother)
    verify("arrived", ask(:mother, "it's time to give birth"))
    verify("wailing", ask(:baby, "spank"))
  end
end
