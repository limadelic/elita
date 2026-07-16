defmodule Doble9Test do
  use Tester
  @moduletag :xunit

  setup context do
    reset_tape_writer()
    cassette = cassette_for(context.test)
    System.put_env("CASSETTE", cassette)
    kill(:doble9)
    kill(:top)
    kill(:left)
    kill(:bottom)
    kill(:right)
    spawn(:doble9)
    spawn(:top, [:player, :greed])
    spawn(:left, [:player, :greed])
    spawn(:bottom, [:player, :greed])
    spawn(:right, [:player, :greed])

    on_exit(fn ->
      kill(:doble9)
      kill(:top)
      kill(:left)
      kill(:bottom)
      kill(:right)
    end)

    :ok
  end

  defp reset_tape_writer do
    Tape.Writer.acquire(fn -> :ok end)
  end

  defp cassette_for(:"test dominoes on start"), do: "doble9"

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

  test "dominoes on start" do
    ask(:doble9, "start a new game with players: top, left, bottom, right")
    verify("9", ask(:doble9, "i need 10 dominoes"))
  end
end
