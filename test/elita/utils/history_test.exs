defmodule HistoryTest do
  use ExUnit.Case
  alias History

  test "records text part as model message" do
    parts = [%{"text" => "hello world"}]
    state = %{history: []}
    
    {:act, "", new_state} = History.record(parts, state)
    
    assert new_state.history == [%{role: "model", parts: [%{text: "hello world"}]}]
  end

  test "records function result as user message" do
    parts = [%{"result" => "stored successfully"}]
    state = %{history: []}
    
    {:reply, "", new_state} = History.record(parts, state)
    
    assert new_state.history == [%{role: "user", parts: [%{text: "stored successfully"}]}]
  end

  test "records multiple parts with text and results" do
    parts = [
      %{"text" => "I'll store that for you"},
      %{"result" => "stored successfully"}
    ]
    state = %{history: []}
    
    {:reply, "", new_state} = History.record(parts, state)
    
    expected = [
      %{role: "model", parts: [%{text: "I'll store that for you"}]},
      %{role: "user", parts: [%{text: "stored successfully"}]}
    ]
    assert new_state.history == expected
  end

  test "appends to existing history" do
    existing = [%{role: "user", parts: [%{text: "previous message"}]}]
    parts = [%{"text" => "new response"}]
    state = %{history: existing}
    
    {:act, "", new_state} = History.record(parts, state)
    
    expected = [
      %{role: "user", parts: [%{text: "previous message"}]},
      %{role: "model", parts: [%{text: "new response"}]}
    ]
    assert new_state.history == expected
  end

  test "ignores empty parts" do
    parts = [%{}, %{"text" => "hello"}]
    state = %{history: []}
    
    {:act, "", new_state} = History.record(parts, state)
    
    assert new_state.history == [%{role: "model", parts: [%{text: "hello"}]}]
  end

  test "ignores unknown part types" do
    parts = [%{"unknown" => "data"}, %{"text" => "hello"}]
    state = %{history: []}
    
    {:act, "", new_state} = History.record(parts, state)
    
    assert new_state.history == [%{role: "model", parts: [%{text: "hello"}]}]
  end

  test "returns reply action for any results" do
    parts = [%{"result" => "stored"}]
    state = %{history: []}
    
    result = History.record(parts, state)
    
    assert {:reply, "", _} = result
  end

  test "returns continue action when no results" do
    parts = [%{"text" => "hello"}]
    state = %{history: []}
    
    result = History.record(parts, state)
    
    assert {:act, "", _} = result
  end
end