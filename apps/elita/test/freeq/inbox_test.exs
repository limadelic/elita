defmodule FreeqInboxTest do
  use ExUnit.Case

  @refusal ":freeq 404 alice #the-lab :Flood protection: sending too fast"

  test "a refused message raises with the server text" do
    assert_raise RuntimeError, ~r/Flood protection: sending too fast/, fn ->
      Freeq.Inbox.route([@refusal], %{})
    end
  end

  @echo ":alice!u@h PRIVMSG #the-lab :bob: hello"
  @other ":bob!u@h PRIVMSG #the-lab :alice: hi"
  @twin ":alice2!u@h PRIVMSG #the-lab :bob: hello"

  defp state(pending, driver) do
    %{
      agent: "alice",
      channel: "#the-lab",
      ask: fn _, _ -> {:error, :none} end,
      driver: driver,
      pending: pending
    }
  end

  test "the server echoing our message back clears it from the queue" do
    {:noreply, state} = Freeq.Inbox.route([@echo], state(["bob: hello", "bob: again"], nil))
    assert state.pending == ["bob: again"]
  end

  test "another nick speaking clears nothing" do
    {:noreply, state} = Freeq.Inbox.route([@other], state(["bob: hello"], "bob"))
    assert state.pending == ["bob: hello"]
  end

  test "a nick that merely starts with ours clears nothing" do
    {:noreply, state} = Freeq.Inbox.route([@twin], state(["bob: hello"], "alice2"))
    assert state.pending == ["bob: hello"]
  end
end
