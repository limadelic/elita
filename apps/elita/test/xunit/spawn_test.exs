defmodule SpawnTest do
  use Tester
  @moduletag :xunit

  @tag cassette: "boss"
  test "spawn creates agents that route messages" do
    spawn(:boss)
    spawn(:dev, :worker)
    spawn(:qa, :worker)
    tell(:boss, "you manage a software development team with a dev and a qa")
    tell(:boss, "we need more test created")
    verify("no", ask(:dev, "did you receive a task from boss?"))
    verify("yes", ask(:qa, "did you receive a task from boss?"))
  end

  @tag cassette: "boss"
  test "routing multi-word msg to named agent hits agent" do
    spawn(:boss)
    spawn(:dev, :worker)
    msg = "did you receive a task from boss?"
    verify("no", ask(:dev, msg))
  end

  test "spawn reads TAPE from env when tape_env not provided" do
    System.put_env("TAPE", "rec")
    on_exit(fn -> System.delete_env("TAPE") end)
    spawn_no_tape_opts("tapetest", ["worker"])
    on_exit(fn -> kill_agent("tapetest") end)
    pid = agent_pid("tapetest")
    assert pid != nil
    state = :sys.get_state(pid)
    assert state.tape == "rec"
  end

  test "spawn does not set tape from env when TAPE unset" do
    System.delete_env("TAPE")
    spawn_no_tape_opts("tapeno", ["worker"])
    on_exit(fn -> kill_agent("tapeno") end)
    pid = agent_pid("tapeno")
    assert pid != nil
    state = :sys.get_state(pid)
    refute Map.get(state, :tape) == "rec"
  end

  defp spawn_no_tape_opts(name, configs) do
    kill_agent(name)
    Elita.spawn(to_string(name), to_configs(configs))
  end

  defp to_configs(configs) when is_list(configs) do
    configs |> Enum.map(&to_string/1)
  end

  defp to_configs(config) do
    [to_string(config)]
  end

  defp agent_pid(name) do
    {:via, Registry, {ElitaRegistry, String.downcase(name), %{kind: :native, folder: nil}}}
    |> GenServer.whereis()
  end

  defp kill_agent(name) do
    case agent_pid(name) do
      nil -> :ok
      pid -> GenServer.stop(pid)
    end
  end
end
