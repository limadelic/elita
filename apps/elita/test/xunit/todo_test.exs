defmodule TodoTest do
  use Tester
  @moduletag :xunit

  setup context do
    System.put_env("CASSETTE", cassette_for(context.test))
    spawn(:todo)
    :ok
  end

  defp cassette_for(:"test todo marks tasks complete"), do: "todomark"
  defp cassette_for(:"test todo remembers tasks"), do: "todoremember"
  defp cassette_for(:"test todo handles multiple tasks"), do: "todomultiple"

  test "todo marks tasks complete" do
    tell(:todo, "Add call dentist to my list")
    tell(:todo, "Mark call dentist as done")
    verify("no", ask(:todo, "What do I need to do?"))
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
end
