defmodule BirthTest do
  use Tester
  @moduletag :xunit

  setup do
    System.put_env("CASSETTE", "birth_xunit")

    on_exit(fn ->
      System.delete_env("CASSETTE")
    end)

    spawn(:mother)
    spawn(:judge)
    :ok
  end

  test "mother gives birth to baby" do
    ask(:mother, "it's time to give birth")

    result = ask(:baby, "what do you do?")
    judge(result, "the baby is crying")
  end
end
