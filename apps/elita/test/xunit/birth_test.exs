defmodule BirthTest do
  use Tester
  @moduletag :xunit

  test "mother births a baby" do
    spawn(:mother)
    response = ask(:mother, "[from el] You are mother. It's time to give birth. Stay in character.")
    verify("gasping", response)
  end
end
