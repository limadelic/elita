defmodule FreeqInboxTest do
  use ExUnit.Case

  @refusal ":freeq 404 alice #the-lab :Flood protection: sending too fast"

  setup do
    Application.put_env(:elita, :flood_window, 0)
    on_exit(fn -> Application.delete_env(:elita, :flood_window) end)
    :ok
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
      pending: pending,
      attempts: 0
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

  test "a refused message is scheduled to go again" do
    {:noreply, state} = Freeq.Inbox.route([@refusal], state(["bob: hello"], nil))
    assert_receive {:retry, "bob: hello"}
    assert state.attempts == 1
  end

  test "refused too many times, it raises with the server's own words" do
    state = %{state(["bob: hello"], nil) | attempts: 3}

    assert_raise RuntimeError, ~r/Flood protection: sending too fast/, fn ->
      Freeq.Inbox.route([@refusal], state)
    end
  end

  test "a refusal with nothing queued raises rather than guessing" do
    assert_raise RuntimeError, ~r/never queued/, fn ->
      Freeq.Inbox.route([@refusal], state([], nil))
    end
  end
end
