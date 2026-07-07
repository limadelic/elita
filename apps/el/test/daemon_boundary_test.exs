defmodule DaemonBoundaryTest do
  use ExUnit.Case
  @moduletag :main

  setup do
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
    System.cmd("pkill", ["-f", "el.*daemon"], stderr_to_stdout: true)
    Process.sleep(100)
  end

  test "daemon handles ls requests", %{testdir: testdir} do
    File.write!(Path.join(testdir, "agent_one"), "")
    el_path = Path.expand("../el", __DIR__)

    start_daemon(el_path)
    Process.sleep(500)

    {output1, exit_code1} = System.cmd(
      "sh",
      ["-c", "cd #{testdir} && #{el_path} ls"],
      stderr_to_stdout: true
    )

    assert exit_code1 == 0, "first ls failed with exit code #{exit_code1}: #{output1}"

    {output2, exit_code2} = System.cmd(
      "sh",
      ["-c", "cd #{testdir} && #{el_path} ls"],
      stderr_to_stdout: true
    )

    assert exit_code2 == 0, "second ls failed with exit code #{exit_code2}: #{output2}"
    assert String.contains?(output2, "agent_one file asleep"),
      "Expected 'agent_one file asleep' in output, got: #{inspect(output2)}"
  end

  test "ls works without daemon running", %{testdir: testdir} do
    File.write!(Path.join(testdir, "agent_one"), "")
    el_path = Path.expand("../el", __DIR__)

    {output, exit_code} = System.cmd(
      "sh",
      ["-c", "cd #{testdir} && #{el_path} ls"],
      stderr_to_stdout: true
    )

    assert exit_code == 0, "ls failed with exit code #{exit_code}: #{output}"
    assert String.contains?(output, "agent_one file asleep"),
      "Expected 'agent_one file asleep' in output, got: #{inspect(output)}"
  end

  test "ls auto-spawns daemon on cold start", %{testdir: testdir} do
    File.write!(Path.join(testdir, "agent_one"), "")
    el_path = Path.expand("../el", __DIR__)

    kill_daemon()
    Process.sleep(200)

    System.put_env("EL_DAEMON_SPAWN", "true")

    {output1, exit_code1} = System.cmd(
      "sh",
      ["-c", "cd #{testdir} && #{el_path} ls"],
      stderr_to_stdout: true
    )

    assert exit_code1 == 0, "first ls failed with exit code #{exit_code1}: #{output1}"
    assert String.contains?(output1, "agent_one file asleep"),
      "Expected 'agent_one file asleep' in output, got: #{inspect(output1)}"

    {output2, exit_code2} = System.cmd(
      "sh",
      ["-c", "cd #{testdir} && #{el_path} ls"],
      stderr_to_stdout: true
    )

    assert exit_code2 == 0, "second ls failed with exit code #{exit_code2}: #{output2}"
    assert String.contains?(output2, "agent_one file asleep"),
      "Expected 'agent_one file asleep' in output, got: #{inspect(output2)}"
  end

  defp start_daemon(el_path) do
    spawn(fn ->
      System.cmd(el_path, ["daemon"], stderr_to_stdout: true)
    end)
  end
end
