defmodule LsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    Agent.Registry.create()
    tmpdir = Path.join(System.tmp_dir!(), "elita_ls_test_#{unique_id()}")
    File.mkdir_p!(tmpdir)

    on_exit(fn ->
      File.rm_rf!(tmpdir)
    end)

    {:ok, tmpdir: tmpdir}
  end

  defp unique_id do
    System.unique_integer([:positive]) |> Integer.to_string()
  end

  test "lists agents in folder", %{tmpdir: tmpdir} do
    File.write!(Path.join(tmpdir, "agent_one"), "")
    File.mkdir!(Path.join(tmpdir, "agent_two"))

    output = capture_io(fn ->
      El.Commands.Ls.execute(cwd: tmpdir)
    end)

    assert String.contains?(output, "agent_one file asleep")
    assert String.contains?(output, "agent_two folder asleep")
  end

  test "marks registered agents as active", %{tmpdir: tmpdir} do
    File.write!(Path.join(tmpdir, "work"), "")
    Agent.Registry.register("work", tmpdir, spawn(fn -> :ok end))

    output = capture_io(fn ->
      El.Commands.Ls.execute(cwd: tmpdir)
    end)

    assert String.contains?(output, "work file active")
  end

  test "sorts agents by name", %{tmpdir: tmpdir} do
    File.write!(Path.join(tmpdir, "zebra"), "")
    File.write!(Path.join(tmpdir, "apple"), "")
    File.mkdir!(Path.join(tmpdir, "monkey"))

    output = capture_io(fn ->
      El.Commands.Ls.execute(cwd: tmpdir)
    end)

    apple_pos = String.to_integer(Integer.to_string(:binary.match(output, "apple") |> elem(0)))
    monkey_pos = String.to_integer(Integer.to_string(:binary.match(output, "monkey") |> elem(0)))
    zebra_pos = String.to_integer(Integer.to_string(:binary.match(output, "zebra") |> elem(0)))

    assert apple_pos < monkey_pos
    assert monkey_pos < zebra_pos
  end

  test "shows no agents when folder empty", %{tmpdir: tmpdir} do
    output = capture_io(fn ->
      El.Commands.Ls.execute(cwd: tmpdir)
    end)

    assert String.contains?(output, "no agents")
  end
end
