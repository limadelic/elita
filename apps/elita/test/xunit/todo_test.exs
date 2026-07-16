defmodule TodoTest do
  use Tester
  @moduletag :xunit

  setup_all do
    spawn(:todo)
    :ok
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
end
