Code.require_file("../../elita/test/tester.exs", __DIR__)

defmodule AskTest do
  use Tester
  @moduletag :main

  setup do
    unless System.get_env("LIVE") || System.get_env("TAPE") == "rec" do
      System.put_env("TAPE", "replay")
    end

    System.put_env("CASSETTE", "el")

    on_exit(fn ->
      try do
        halt(:el)
      rescue
        _ -> :ok
      catch
        :exit, _ -> :ok
      end
      try do
        halt(:greet)
      rescue
        _ -> :ok
      catch
        :exit, _ -> :ok
      end
      System.delete_env("TAPE")
      System.delete_env("CASSETTE")
    end)

    spawn(:el)
    spawn(:greet)
    :ok
  end

  test "el routes ask to greet" do
    verify(:el, "Who am I talking to", "ask greet hello")
  end
end
