defmodule BirthUnitTest do
  use Tester
  @moduletag :main

  setup do
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", "birth")

    on_exit(fn ->
      System.delete_env("TAPE")
      System.delete_env("CASSETTE")
    end)

    spawn(:mother)
    :ok
  end

  test "mother gives birth to baby" do
    ask(:mother, "it's time to give birth")

    verify(:baby, "cry", "spank")
  end
end
