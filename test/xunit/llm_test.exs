defmodule LlmTest do
  use ExUnit.Case

  test "basic llm call" do
    response = Lite.llm("say hello")
    IO.inspect(response, label: "LLM response")
    assert is_binary(response)
  end
end
