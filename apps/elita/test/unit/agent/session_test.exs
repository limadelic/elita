defmodule Agent.SessionUnitTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = Agent.Session.start_link(name: :test, folder: "/tmp", runner: &stub_claude/2)
    {:ok, pid: pid}
  end

  test "ask sends message and returns response", %{pid: pid} do
    {:ok, response} = Agent.Session.ask(pid, "hello")
    assert response == "stub response"
  end

  test "cast sends message without waiting for response", %{pid: pid} do
    :ok = Agent.Session.cast(pid, "hello")
  end

  @tag :live
  test "kills os process on timeout" do
    {:ok, pid} =
      Agent.Session.start_link(name: :timeout_test, folder: "/tmp", runner: &sleep_runner/2)

    {:ok, os_pid} = Agent.Session.ask(pid, "sleep")

    :timer.sleep(100)

    refute process_alive?(os_pid), "OS process should be killed after timeout"
  end

  defp stub_claude(_message, _folder) do
    "stub response"
  end

  defp sleep_runner(_message, _folder) do
    port = Port.open({:spawn_executable, "/bin/sleep"}, [{:args, ["300"]}, :binary, :exit_status])
    {:os_pid, os_pid} = :erlang.port_info(port, :os_pid)

    try do
      read_sleep_response(port, os_pid, "")
    after
      Port.close(port)
    end
  end

  defp read_sleep_response(port, os_pid, acc) do
    receive do
      {^port, _msg} -> read_sleep_response(port, os_pid, acc)
    after
      30000 ->
        to_string(os_pid)
    end
  end

  defp process_alive?(pid_str) when is_binary(pid_str) do
    pid = String.to_integer(pid_str)
    process_alive?(pid)
  end

  defp process_alive?(os_pid) when is_integer(os_pid) do
    case System.cmd("ps", ["-p", to_string(os_pid)]) do
      {_output, 0} -> true
      {_output, _} -> false
    end
  end
end
