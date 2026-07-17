defmodule BirthTest do
  use Tester
  @moduletag :xunit

  test "mother births a baby" do
    spawn(:mother)
    verify("beautiful baby", ask(:mother, "it's time to give birth"))
    verify("wailing", ask(:baby, "spank"))
  end
end
