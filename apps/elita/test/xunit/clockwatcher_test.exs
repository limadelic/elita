defmodule ClockwatcherTest do
  use Tester
  @moduletag :xunit

  setup context do
    reset_tape_writer()
    cassette = cassette_for(context.test)
    System.put_env("CASSETTE", cassette)
    kill(:clockwatcher)
    spawn(:clockwatcher)
    on_exit(fn -> kill(:clockwatcher) end)
    :ok
  end

  defp reset_tape_writer do
    Tape.Writer.acquire(fn -> :ok end)
  end

  defp cassette_for(:"test clockwatcher respects work hours"), do: "clockwatcher"

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

  test "clockwatcher respects work hours" do
    verify("10:00", ask(:clockwatcher, "can you handle this task?"))
  end
end
