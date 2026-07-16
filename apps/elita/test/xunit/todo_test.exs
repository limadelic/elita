defmodule TodoTest do
  use Tester
  @moduletag :xunit

  setup do
    reset_tape_writer()
    kill(:todo)
    spawn(:todo)
    on_exit(fn -> kill(:todo) end)
    :ok
  end

  defp reset_tape_writer do
    # Use acquire to get the current state and reset it
    Tape.Writer.acquire(fn -> :ok end)
  end

  test "todo remembers tasks" do
    ask(:todo, "Add buy groceries to my list")
    verify("groceries", ask(:todo, "What do I need to do?"))
  end

  test "todo handles multiple tasks" do
    tell(:todo, "Add buy milk to my list")
    tell(:todo, "Add walk dog to my list")
    verify("milk", ask(:todo, "What do I need to do?"))
    verify("dog", ask(:todo, "What do I need to do?"))
  end

  test "todo marks tasks complete" do
    tell(:todo, "Add call dentist to my list")
    tell(:todo, "Mark call dentist as done")
    verify("no", ask(:todo, "What do I need to do?"))
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
end
