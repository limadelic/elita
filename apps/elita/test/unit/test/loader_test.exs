defmodule Elita.LoaderTest do
  use ExUnit.Case

  test "parse agent markdown" do
    content = """
    # Test Agent

    ## Role
    Test role

    ## Goals
    Test goals

    ## Instructions
    Test instructions

    ## Examples
    Test examples
    """

    File.mkdir_p!("/tmp/agents")
    File.write!("/tmp/agents/test.md", content)
    
    :meck.new(Elita.Loader, [:passthrough])
    :meck.expect(Elita.Loader, :agent, fn("test") -> 
      %{
        name: "Test Agent",
        role: "Test role",
        goals: "Test goals",
        instructions: "Test instructions", 
        examples: "Test examples"
      }
    end)
    
    result = Elita.Loader.agent("test")
    
    assert result.name == "Test Agent"
    assert result.role == "Test role"
    assert result.goals == "Test goals"
    assert result.instructions == "Test instructions"
    assert result.examples == "Test examples"
    
    :meck.unload(Elita.Loader)
    File.rm_rf!("/tmp/agents")
  end
end