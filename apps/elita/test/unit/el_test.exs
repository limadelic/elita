defmodule ElUnitTest do
  use Tester
  @moduletag :main
  @moduletag :spec

  describe "routing messages" do
    setup do
      unless System.get_env("LIVE") || System.get_env("TAPE") == "rec" do
        System.put_env("TAPE", "replay")
      end

      System.put_env("CASSETTE", "el")

      on_exit(fn ->
        System.delete_env("TAPE")
        System.delete_env("CASSETTE")
      end)

      spawn(:el)
      spawn(:greet)
      :ok
    end

    @tag :live
    test "el routes ask message to greet agent" do
      verify(:el, "Who am I talking to", "ask greet hello")
      verify(:el, "Mike", "ask greet Mike")
      verify(:el, "Greeeet", "ask greet how are you")
    end
  end
end
