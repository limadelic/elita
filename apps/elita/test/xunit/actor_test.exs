defmodule ActorTest do
  use Tester
  @moduletag :xunit

  setup context do
    reset_tape_writer()
    cassette = cassette_for(context.test)
    System.put_env("CASSETTE", cassette)
    kill(:actor)
    spawn(:actor, :speck)
    on_exit(fn -> kill(:actor) end)
    :ok
  end

  defp reset_tape_writer do
    Tape.Writer.acquire(fn -> :ok end)
  end

  defp cassette_for(:"test actor speck passes"), do: "actor_speck"

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

  @moduletag timeout: 120_000
  test "actor speck passes" do
    verify("passed", ask(:actor, "exec actor"))
  end
end
