defmodule SpeckTest do
  use Tester
  @moduletag :xunit

  @tag cassette: "mother"
  test "speck runs mother spec" do
    spawn(:speck)
    verify("PASSED", ask(:speck, "exec mother"))
  end

  @tag cassette: "diagnose"
  test "speck runs doctor spec" do
    spawn(:speck)
    verify("PASSED", ask(:speck, "exec doctor"))
  end

  @tag cassette: "delegate"
  test "speck runs boss spec" do
    spawn(:speck)
    verify("PASSED", ask(:speck, "exec boss"))
  end
end
