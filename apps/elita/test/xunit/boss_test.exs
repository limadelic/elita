defmodule BossTest do
  use Tester
  @moduletag :xunit

  setup context do
    reset_tape_writer()
    cassette = cassette_for(context.test)
    System.put_env("CASSETTE", cassette)
    kill_all()
    spawn_agents()
    on_exit(fn -> kill_all() end)
    :ok
  end

  defp reset_tape_writer do
    Tape.Writer.acquire(fn -> :ok end)
  end

  defp cassette_for(:"test boss delegates task to worker"), do: "boss"
  defp cassette_for(:"test michael asks dwight to photocopy sales reports"), do: "boss2"

  defp kill_all do
    kill(:boss)
    kill(:dev)
    kill(:qa)
    kill(:michael)
    kill(:dwight)
    kill(:pam)
    kill(:jim)
  end

  defp spawn_agents do
    :ok
  end

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

  test "boss delegates task to worker" do
    spawn(:boss)
    spawn(:dev, :worker)
    spawn(:qa, :worker)
    tell(:boss, "you manage a software development team with a dev and a qa")
    verify("done", ask(:boss, "we need more test created"))
    verify("no", ask(:dev, "did you receive a task from boss?"))
    verify("yes", ask(:qa, "did you receive a task from boss?"))
  end

  test "michael asks dwight to photocopy sales reports" do
    spawn(:michael, :boss)
    spawn(:dwight, :boss)
    spawn(:pam, :worker)
    spawn(:jim, :worker)
    tell(:michael, "you manage dwight the assistant regional manager")
    tell(:dwight, "you manage pam the receptionist and jim the salesman")
    verify("done", ask(:michael, "we need 50 copies of the quarterly sales report"))
    poll_pam_task(120_000, 500)
    verify("no", ask(:jim, "did you receive a task?"))
  end

  defp poll_pam_task(remaining, _interval) when remaining <= 0 do
    {:error, "timeout waiting for pam to receive task"}
  end

  defp poll_pam_task(remaining, interval) do
    result = ask(:pam, "did you receive a task to make copies?")

    if String.downcase(result) =~ ~r/\byes\b/ do
      :ok
    else
      Process.sleep(interval)
      poll_pam_task(remaining - interval, interval)
    end
  end
end
