defmodule Elita.AgentTest do
  use ExUnit.Case
  alias Elita.Agent

  test "act uses conversation history" do
    :meck.new(Elita.Loader, [:non_strict])
    :meck.new(Elita.Prompt, [:non_strict])
    :meck.new(Elita.Pat, [:non_strict])
    
    :meck.expect(Elita.Loader, :agent, fn("test_agent") -> %{name: "Test"} end)
    :meck.expect(Elita.Prompt, :prompt, fn(_agent, conversation_prompt) -> 
      assert String.contains?(conversation_prompt, "user: test context")
      "prompt result" 
    end)
    :meck.expect(Elita.Pat, :say, fn(_prompt) -> {:ok, "response"} end)
    
    result = Agent.act("test_agent", "test context")
    
    assert result == {:ok, "response"}
    assert :meck.called(Elita.Loader, :agent, ["test_agent"])
    assert :meck.called(Elita.Pat, :say, ["prompt result"])
    
    :meck.unload()
  end
end