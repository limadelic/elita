defmodule ClockwatcherTest do
  use Tester
  @moduletag :xunit

  @cases [
    {"2025-07-07 06:00:00", "early", "don't start until 9"},
    {"2025-07-07 10:00:00", "clockwatcher", "yes, I can help"},
    {"2025-07-07 12:30:00", "lunch", "lunch"},
    {"2025-07-07 18:00:00", "late", "done for the day"},
    {"2025-07-12 10:00:00", "weekend", "come back on Monday"}
  ]

  for {time, cassette, fragment} <- @cases do
    @tag cassette: cassette
    test "#{cassette}" do
      System.put_env("CLOCK", unquote(time))
      spawn(:clockwatcher)
      result = ask(:clockwatcher, "can you handle this task?")
      verify(unquote(fragment), result)
    end
  end
end
