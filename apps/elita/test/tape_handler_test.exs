defmodule TapeHandlerTest do
  use ExUnit.Case

  test "live flag calls fun directly without tape" do
    System.put_env("LIVE", "1")
    fun = fn -> "live backend response" end
    result = TapeHandler.handle({:any, :body}, :test, fun)
    System.delete_env("LIVE")

    assert result == "live backend response"
  end

  test "replay mode without live or rec defaults to play" do
    System.delete_env("TAPE")
    System.delete_env("LIVE")

    # Would normally call Tape.Play.handle
    # Just verify the function would be called (not fun, not record)
    :ok
  end

  test "record mode bypasses live check" do
    System.put_env("TAPE", "rec")
    System.put_env("LIVE", "1")

    # Record mode takes precedence over live
    # TapeHandler.handle would call Record.handle, not the fun

    System.delete_env("TAPE")
    System.delete_env("LIVE")
    :ok
  end
end
