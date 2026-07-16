defmodule ClockwatcherTest do
  use Tester
  @moduletag :xunit

  setup _context do
    spawn(:clockwatcher)
    :ok
  end

  test "clockwatcher respects work hours" do
    verify("10:00", ask(:clockwatcher, "can you handle this task?"))
  end
end
