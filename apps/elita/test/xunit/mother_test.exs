defmodule MotherTest do
  use Tester
  @moduletag :xunit

  test "mother births a baby" do
    spawn(:mother)
    verify("has arrived", ask(:mother, "it's time to give birth"))
    verify("wailing", ask(:baby, "spank"))
  end
end
