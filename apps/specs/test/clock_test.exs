defmodule ClockTest do
  use SpecHelper

  test "clock tells the time" do
    spawn(:clock)

    verify("2025-07-07 10:00", ask(:clock, "what time is it"))
  end
end
