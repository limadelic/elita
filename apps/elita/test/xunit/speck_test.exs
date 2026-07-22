defmodule SpeckTest do
  use Tester
  @moduletag :xunit

  @tag cassette: "mother"
  test "speck runs mother spec" do
    spawn(:speck)
    verify("PASSED", ask(:speck, "exec mother"))
  end
end
