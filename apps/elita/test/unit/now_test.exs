defmodule NowUnitTest do
  use ExUnit.Case
  @moduletag :main

  setup do
    System.delete_env("TAPE")
    System.delete_env("LIVE")
    clock = Application.get_env(:elita, :clock)
    Application.put_env(:elita, :clock, fn -> {{2025, 7, 2}, {23, 45, 30}} end)

    on_exit(fn ->
      Application.put_env(:elita, :clock, clock)
    end)

    :ok
  end

  test "text returns formatted string from pinned clock" do
    result = Now.text()
    assert result == "2025-07-02 23:45:30"
  end
end
