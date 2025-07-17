defmodule E2E.ToolCallingTest do
  use ExUnit.Case, async: false
  alias Elita.Tools

  test "tool parsing extracts set tool correctly" do
    llm_response = """
    <function_calls>
    <invoke name="set">
    <parameter name="field">last_move</parameter>
    <parameter name="value">played [3,6]</parameter>
    </invoke>
    </function_calls>
    """
    
    state = %{memory: %{}}
    {:tools_executed, _results, new_state} = Tools.process({:ok, llm_response}, state)
    
    assert new_state.memory["last_move"] == "played [3,6]"
  end

  test "tool parsing extracts say tool correctly" do
    llm_response = """
    <function_calls>
    <invoke name="say">
    <parameter name="message">Player knocked, skipping turn</parameter>
    </invoke>
    </function_calls>
    """
    
    state = %{memory: %{}}
    {:tools_executed, results, _new_state} = Tools.process({:ok, llm_response}, state)
    
    result_string = Enum.join(results, ", ")
    assert String.contains?(result_string, "broadcasted")
    assert String.contains?(result_string, "Player knocked, skipping turn")
  end

  test "tool parsing handles multiple tools" do
    llm_response = """
    <function_calls>
    <invoke name="set">
    <parameter name="field">game_state</parameter>
    <parameter name="value">active</parameter>
    </invoke>
    <invoke name="say">
    <parameter name="message">Game started, let's play!</parameter>
    </invoke>
    </function_calls>
    """
    
    state = %{memory: %{}}
    {:tools_executed, results, new_state} = Tools.process({:ok, llm_response}, state)
    
    result_string = Enum.join(results, ", ")
    assert String.contains?(result_string, "stored")
    assert String.contains?(result_string, "broadcasted")
    assert new_state.memory["game_state"] == "active"
  end
end