defmodule DaemonBoundaryTest do
  use ExUnit.Case
  @moduletag :main

  setup do
    kill_daemon()
    testdir = Path.join(System.tmp_dir!(), "el_daemon_#{unique_id()}")
    File.mkdir_p!(testdir)

    on_exit(fn ->
      kill_daemon()
      File.rm_rf!(testdir)
    end)

    {:ok, testdir: testdir}
  end

  defp unique_id do
    System.unique_integer([:positive]) |> Integer.to_string()
  end

  defp kill_daemon do
    System.cmd("pkill", ["-9", "-f", "el.*daemon"], stderr_to_stdout: true)
    Process.sleep(300)
  end

  test "daemon mode toggles node marker in ls output", %{testdir: testdir} do
    File.write!(Path.join(testdir, "agent_one"), "")
    el_path = Path.expand("../el", __DIR__)

    {output_local, exit_code_local} = System.cmd(
      "sh",
      ["-c", "cd #{testdir} && #{el_path} ls"],
      stderr_to_stdout: true
    )

    assert exit_code_local == 0, "local ls failed: #{inspect(output_local)}"
    refute String.contains?(output_local, "elita@"),
      "Expected no 'elita@' marker in local output, got: #{inspect(output_local)}"
    assert String.contains?(output_local, "agent_one file asleep"),
      "Expected 'agent_one file asleep' in output, got: #{inspect(output_local)}"

    start_daemon(el_path)
    Process.sleep(500)

    {output_daemon, exit_code_daemon} = System.cmd(
      "sh",
      ["-c", "cd #{testdir} && #{el_path} ls"],
      stderr_to_stdout: true
    )

    assert exit_code_daemon == 0, "daemon ls failed: #{inspect(output_daemon)}"
    assert String.contains?(output_daemon, "elita@"),
      "Expected 'elita@' marker in daemon output, got: #{inspect(output_daemon)}"
    assert String.contains?(output_daemon, "agent_one file asleep"),
      "Expected 'agent_one file asleep' in output, got: #{inspect(output_daemon)}"

    kill_daemon()
    Process.sleep(200)

    {output_after_kill, exit_code_after} = System.cmd(
      "sh",
      ["-c", "cd #{testdir} && #{el_path} ls"],
      stderr_to_stdout: true
    )

    assert exit_code_after == 0, "ls after kill failed: #{inspect(output_after_kill)}"
    refute String.contains?(output_after_kill, "elita@"),
      "Expected no 'elita@' marker after daemon killed, got: #{inspect(output_after_kill)}"
    assert String.contains?(output_after_kill, "agent_one file asleep"),
      "Expected 'agent_one file asleep' in output, got: #{inspect(output_after_kill)}"
  end

  defp start_daemon(el_path) do
    Port.open({:spawn_executable, "/bin/sh"}, [
      {:args, ["-c", "#{el_path} daemon &"]},
      :exit_status
    ])
    |> Port.close()
  end
end
