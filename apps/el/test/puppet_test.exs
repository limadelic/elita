Code.require_file("../../elita/test/tester.exs", __DIR__)

defmodule PuppetTest do
  use ExUnit.Case
  import ExUnit.Assertions

  @moduletag :live
  @session "dude"

  setup do
    boot_session()
    on_exit(fn -> teardown_session() end)
    :ok
  end

  defp boot_session do
    if System.get_env("LIVE") == "1" do
      boot_real_session()
    else
      boot_fake_session()
    end
  end

  defp boot_real_session do
    El.Distribution.start("puppet", host: "127.0.0.1")
    boot_script_path = Path.expand("e2e/boot_session.sh", __DIR__)
    el_path = Path.expand("../el", __DIR__)

    spawn_background_process(boot_script_path, el_path)
    wait_for_connection()
  end

  defp spawn_background_process(boot_script, el_path) do
    spawn(fn ->
      System.cmd(boot_script, [@session, el_path], stderr_to_stdout: true)
    end)

    Process.sleep(2000)
  end

  defp wait_for_connection do
    session_node = String.to_atom("claude_#{@session}@127.0.0.1")
    attempt_connect(session_node, 0)
  end

  defp attempt_connect(_node, attempts) when attempts > 20 do
    raise "Failed to connect to session after 20 attempts"
  end

  defp attempt_connect(node, attempts) do
    case Node.connect(node) do
      true -> :ok
      false ->
        Process.sleep(500)
        attempt_connect(node, attempts + 1)
    end
  end

  defp boot_fake_session do
    {:ok, _pid} = FakeSession.start_link(@session)
    :ok
  end

  defp teardown_session do
    if System.get_env("LIVE") == "1" do
      System.cmd("pkill", ["-f", "expect.*boot_session"], stderr_to_stdout: true)
      System.cmd("pkill", ["-f", "el.*claude.*#{@session}"], stderr_to_stdout: true)
      Process.sleep(200)
    else
      try do
        GenServer.stop(String.to_atom(@session), :normal, 100)
      rescue
        _ -> :ok
      catch
        :exit, _ -> :ok
      end
    end
  end

  test "el ask dude 1 + 1 contains 2" do
    el_path = Path.expand("../el", __DIR__)
    live? = System.get_env("LIVE") == "1"

    env = if live? do
      [{"EL_NODE", "127.0.0.1"}]
    else
      []
    end

    {output, exit_code} = System.cmd(
      el_path,
      ["ask", @session, "1 + 1"],
      env: env,
      stderr_to_stdout: true
    )

    assert exit_code == 0, "el ask failed with exit code #{exit_code}: #{output}"
    assert String.contains?(output, "2"),
      "Expected '2' in output, got: #{inspect(output)}"
  end
end

defmodule FakeSession do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: String.to_atom(name))
  end

  def init(name) do
    {:ok, {name, []}}
  end

  def handle_call({:tap, pid}, _from, {name, taps}) do
    {:reply, :ok, {name, [pid | taps]}}
  end

  def handle_call({:untap, pid}, _from, {name, taps}) do
    {:reply, :ok, {name, List.delete(taps, pid)}}
  end

  def handle_cast({:inject, _msg}, {_name, taps} = state) do
    # Send fake response with idle signal
    response = "2\n\e[?2004h"
    Enum.each(taps, fn pid -> send(pid, {:output, response}) end)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
