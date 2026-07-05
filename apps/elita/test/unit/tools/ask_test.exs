defmodule Tools.Sys.AskUnitTest do
  use Tester
  @moduletag :main
  @moduletag :spec

  describe "ask routes through el" do
    setup do
      unless System.get_env("LIVE") || System.get_env("TAPE") == "rec" do
        System.put_env("TAPE", "replay")
      end

      System.put_env("CASSETTE", "ask")

      on_exit(fn ->
        System.delete_env("TAPE")
        System.delete_env("CASSETTE")
      end)

      spawn(:el)
      spawn(:greet)
      :ok
    end

    @tag :live
    test "ask through el to greet agent" do
      verify(:el, "Who am I talking to?", "ask greet hello")
    end
  end
end
