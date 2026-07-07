defmodule LsBoundaryTest do
  use ExUnit.Case

  @moduletag :main

  setup do
    testdir = Path.join(System.tmp_dir!(), "el_ls_boundary_#{unique_id()}")
    File.mkdir_p!(testdir)

    on_exit(fn ->
      File.rm_rf!(testdir)
    end)

    {:ok, testdir: testdir}
  end

  defp unique_id do
    System.unique_integer([:positive]) |> Integer.to_string()
  end

  test "el ls boundary test shows files and folders", %{testdir: testdir} do
    File.write!(Path.join(testdir, "agent_one"), "")
    File.mkdir!(Path.join(testdir, "agent_two"))

    el_path = Path.expand("../el", __DIR__)

    {output, exit_code} =
      System.cmd(
        "sh",
        ["-c", "cd #{testdir} && #{el_path} ls"],
        stderr_to_stdout: true
      )

    assert exit_code == 0, "el ls failed with exit code #{exit_code}: #{output}"

    assert String.contains?(output, "agent_one file asleep"),
           "Expected 'agent_one file asleep' in output, got: #{inspect(output)}"

    assert String.contains?(output, "agent_two folder asleep"),
           "Expected 'agent_two folder asleep' in output, got: #{inspect(output)}"
  end

  test "el ls boundary test hides dotfiles", %{testdir: testdir} do
    File.write!(Path.join(testdir, "visible"), "")
    File.write!(Path.join(testdir, ".hidden"), "")

    el_path = Path.expand("../el", __DIR__)

    {output, exit_code} =
      System.cmd(
        "sh",
        ["-c", "cd #{testdir} && #{el_path} ls"],
        stderr_to_stdout: true
      )

    assert exit_code == 0, "el ls failed with exit code #{exit_code}: #{output}"

    assert String.contains?(output, "visible file asleep"),
           "Expected 'visible' in output, got: #{inspect(output)}"

    refute String.contains?(output, ".hidden"),
           "Dotfiles should be hidden, but '.hidden' found in: #{inspect(output)}"
  end

  test "el ls boundary test shows no agents for empty folder", %{
    testdir: testdir
  } do
    el_path = Path.expand("../el", __DIR__)

    {output, exit_code} =
      System.cmd(
        "sh",
        ["-c", "cd #{testdir} && #{el_path} ls"],
        stderr_to_stdout: true
      )

    assert exit_code == 0, "el ls failed with exit code #{exit_code}: #{output}"

    assert String.contains?(output, "no agents"),
           "Expected 'no agents' for empty folder, got: #{inspect(output)}"
  end
end
