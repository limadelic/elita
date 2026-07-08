defmodule SpecBossTest do
  use Tester

  @moduletag :live
  @moduletag :spec
  @moduletag timeout: 1_200_000

  setup do
    System.put_env("LIVE", "1")
    System.put_env("CASSETTE", "boss_speck")

    if !System.get_env("TAPE") do
      System.put_env("TAPE", "replay")
    end

    on_exit(fn ->
      System.delete_env("LIVE")
      System.delete_env("CASSETTE")
      System.delete_env("TAPE")
    end)

    :ok
  end

  test "boss speck passes" do
    speck(:boss)
  end
end
