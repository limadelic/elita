defmodule CfgTest do
  use ExUnit.Case

  import Cfg, only: [config: 1]

  test "Cfg.config" do
    assert config(:todo) == %{
             name: "todo",
             description: "Todo list manager that tracks tasks and completion status",
             tools: "set, get",
             content: """
             # Todo Agent

             You are Todo - a task management agent. Help users track what needs to be done.\
             """
           }
  end
end
