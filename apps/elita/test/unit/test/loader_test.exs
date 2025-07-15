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

    File.mkdir_p!("agents")
    File.write!("agents/test.md", content)
    
    result = Elita.Loader.agent("test")
    
    assert result.name == "Test Agent"
    assert result.role == "Test role"
    assert result.goals == "Test goals"
    assert result.instructions == "Test instructions"
    assert result.examples == "Test examples"
    
    File.rm!("agents/test.md")
  end
end