defmodule MotherTest do
  use SpecHelper

  @tag cassette: "mother"
  test "mother births a baby" do
    spawn(:mother)
    verify("has arrived", ask(:mother, "it's time to give birth"))
    verify("wailing", ask(:baby, "spank"))
  end
end
