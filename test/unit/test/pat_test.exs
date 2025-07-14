defmodule Elita.PatTest do
  use ExUnit.Case
  alias Elita.Pat

  test "say returns body on 200" do
    :meck.new(HTTPoison, [:non_strict])
    :meck.expect(HTTPoison, :post, fn(_, _, _, _) -> {:ok, %{status_code: 200, body: "response"}} end)
    
    result = Pat.say("test prompt")
    assert result == {:ok, "response"}
    
    :meck.unload(HTTPoison)
  end

  test "say returns error on non-200" do
    :meck.new(HTTPoison, [:non_strict])
    :meck.expect(HTTPoison, :post, fn(_, _, _, _) -> {:ok, %{status_code: 404}} end)
    
    result = Pat.say("test prompt")
    assert result == {:error, "%{status_code: 404}"}
    
    :meck.unload(HTTPoison)
  end

  test "say returns error on request failure" do
    :meck.new(HTTPoison, [:non_strict])
    :meck.expect(HTTPoison, :post, fn(_, _, _, _) -> {:error, :timeout} end)
    
    result = Pat.say("test prompt")
    assert result == {:error, ":timeout"}
    
    :meck.unload(HTTPoison)
  end
end