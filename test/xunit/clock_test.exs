defmodule ClockTest do
  use Tester
  @moduletag :main
  import NaiveDateTime, only: [local_now: 0]

  test "clock gives current hour" do
    spawn :clock
    
    verify :clock, local_now().hour, "what hour is it?"
  end
end