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
    
    {:act, "", new_state} = History.record(parts, state)
    
    assert new_state.history == [%{role: "user", parts: [%{text: "stored successfully"}]}]
  end
end