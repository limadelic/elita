Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqTodoTest do
  use FreeqCase

  @tag cassette: "todoremember"
  test "todo remembers tasks" do
    spawn(:todo)
    ask(:todo, "Add buy groceries to my list")
    verify("groceries", ask(:todo, "What do I need to do?"))

    assert FreeqTestClient.wait_said?("todo", "brian", "groceries")
  end
end
