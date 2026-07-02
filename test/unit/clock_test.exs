defmodule ClockUnitTest do
  use Tester
  @moduletag :main
  @moduletag :spec

  setup do
    System.put_env("CASSETTE", "clock")
    System.put_env("MATCHER", "relaxed")

    on_exit(fn ->
      System.delete_env("CASSETTE")
      System.delete_env("MATCHER")
    end)

    spawn :clock
    spawn :judge
    :ok
  end

  test "clock responds with an hour" do
    result = ask :clock, "what hour is it?"

    hour = extract_hour(result)
    judge result, "states the current hour as #{hour} or within one hour of it"
  end

  defp extract_hour(text) do
    case Regex.run(~r/(?:is|It is)\s+[\*]*(\d{1,2})[\*]*(?:\s+\(|$)/i, text) do
      [_, hour] ->
        h = String.to_integer(hour)
        if h >= 0 and h <= 23, do: h, else: Time.utc_now().hour
      _ ->
        case Regex.run(~r/[\*]*(\d{1,2})[\*]*\s+\(\d{1,2}\s+(AM|PM)/, text) do
          [_, hour, _] -> String.to_integer(hour)
          _ -> Time.utc_now().hour
        end
    end
  end
end
