defmodule BirthTest do
  use Tester
  @moduletag :xunit

  test "mother births a baby" do
    spawn(:mother)
    response = ask(:mother, "it's time to give birth")
    verify("arrived", response)
  end

  test "baby cries when spanked" do
    spawn(:baby)
    response = ask(:baby, "spank")
    verify("cry", response)
  end
end
