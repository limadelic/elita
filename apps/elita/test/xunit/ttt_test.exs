defmodule TttTest do
  use Tester
  @moduletag :xunit

  setup context do
    reset_tape_writer()
    cassette = cassette_for(context.test)
    System.put_env("CASSETTE", cassette)
    kill(:alice)
    kill(:bob)
    spawn(:alice, :ttt)
    spawn(:bob, :ttt)

    on_exit(fn ->
      kill(:alice)
      kill(:bob)
    end)

    :ok
  end

  defp reset_tape_writer do
    Tape.Writer.acquire(fn -> :ok end)
  end

  defp cassette_for(:"test ttt agents play to finish"), do: "ttt"

  defp kill(name) do
    name
    |> to_string()
    |> String.downcase()
    |> then(&{:via, Registry, {ElitaRegistry, &1, %{kind: :native, folder: nil}}})
    |> GenServer.whereis()
    |> case do
      nil -> :ok
      pid -> GenServer.stop(pid)
    end
  end

  test "ttt agents play to finish" do
    tell(:bob, "alice is gonna be your opponent, wait for her move")
    tell(:alice, "start a game with bob, you are X, play first")

    _completed = poll_until_complete(:alice, 120_000, 500)

    result = ask(:alice, "tell me: did the game finish and was it a win or tie?")
    verify_completion(result)
  end

  defp poll_until_complete(_agent, remaining, _interval) when remaining <= 0 do
    {:error, "timeout waiting for game to complete"}
  end

  defp poll_until_complete(agent, remaining, interval) do
    case is_game_complete?(agent) do
      true ->
        :ok

      false ->
        Process.sleep(interval)
        poll_until_complete(agent, remaining - interval, interval)
    end
  end

  defp is_game_complete?(agent) do
    result = ask(agent, "is the game over? answer only: yes or no")
    String.downcase(result) =~ ~r/\byes\b/
  end

  defp verify_completion(result) do
    assert result =~ "game finished"
  end
end
