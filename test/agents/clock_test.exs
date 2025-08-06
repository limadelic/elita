defmodule ClockTest do
  use ExUnit.Case
  import ElitaTester
  import NaiveDateTime, only: [local_now: 0]

  test "clock gives current hour" do
    start :clock
    
    verify :clock, local_now().hour, "what hour is it?"
  end
end