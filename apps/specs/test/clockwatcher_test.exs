defmodule ClockwatcherTest do
  use SpecHelper

  @cases [
    {:early, "2025-07-07 06:00:00", "early", "don't start until 9"},
    {:work, "2025-07-07 10:00:00", "work", "yes, i can help"},
    {:lunch, "2025-07-07 12:30:00", "lunch", "lunch"},
    {:late, "2025-07-07 18:00:00", "late", "done for the day"},
    {:weekend, "2025-07-12 10:00:00", "weekend", "come back monday"}
  ]

  for {name, clock, cassette, fragment} <- @cases do
    @tag cassette: cassette
    @tag clock_override: clock
    test "#{name}" do
      spawn(unquote(name), :clockwatcher)
      result = ask(unquote(name), "can you handle this task?")
      verify(unquote(fragment), result)
    end
  end
end
