defmodule TodoTest do
  use Tester

  setup do
    spawn :todo
    :ok
  end

  test "todo remembers tasks" do
    ask :todo, "Add buy groceries to my list"
    verify :todo, "groceries", "What do I need to do?"
  end

  test "todo handles multiple tasks" do
    tell :todo, "Add buy milk to my list"
    tell :todo, "Add walk dog to my list"
    verify :todo, "milk", "What do I need to do?"
    verify :todo, "dog", "What do I need to do?"
  end

  test "todo marks tasks complete" do
    tell :todo, "Add call dentist to my list"
    tell :todo, "Mark call dentist as done"
    verify :todo, "no", "What do I need to do?"
  end
end