defmodule ClockTest do
  use Tester
  @moduletag :xunit

  test "clock tells the time" do
    spawn(:clock)

    verify("23:52:03", ask(:clock, "what time is it"))
  end
end
