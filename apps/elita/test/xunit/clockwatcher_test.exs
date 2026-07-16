defmodule ClockwatcherTest do
  use Tester
  @moduletag :xunit

  setup context do
    System.put_env("CASSETTE", cassette_for(context.test))
    spawn(:clockwatcher)
    :ok
  end

  defp cassette_for(:"test clockwatcher respects work hours"), do: "clockwatcher"

  test "clockwatcher respects work hours" do
    verify("10:00", ask(:clockwatcher, "can you handle this task?"))
  end
end
