defmodule FreeqInboxTest do
  use ExUnit.Case

  @refusal ":freeq 404 alice #the-lab :Flood protection: sending too fast"

  test "a refused message raises with the server text" do
    assert_raise RuntimeError, ~r/Flood protection: sending too fast/, fn ->
      Freeq.Inbox.route([@refusal], %{})
    end
  end
end
