defmodule ClockwatcherTest do
  use Tester
  @moduletag :xunit

  setup do
    spawn(:clockwatcher)
    :ok
  end

  test "clockwatcher responds correctly for current time" do
    verify(:clockwatcher, response(), "can you handle this task?")
  end

  defp response do
    now = NaiveDateTime.local_now()
    hour = now.hour
    weekday = Date.day_of_week(now)

    cond do
      weekday > 5 -> "come back monday"
      hour < 9 -> "don't start until 9"
      hour in [12, 13] -> "lunch time"
      hour >= 17 -> "done for the day"
      true -> "yes"
    end
  end
end
