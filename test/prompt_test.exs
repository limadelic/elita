defmodule PromptTest do
  use ExUnit.Case
  import Prompt, only: [prompt: 2]

  test "simple agent no header" do
    config = %{
      content: "You are a helpful assistant."
    }

    result = prompt config, []

    assert result == [
             %{
               role: "system",
               content: "You are a helpful assistant."
             }
           ]
  end

  test "agent with history" do
    config = %{
      content: "You are a helpful assistant."
    }

    history = [
      %{role: "user", content: "Hello"},
      %{role: "assistant", content: "Hi there!"}
    ]

    result = prompt config, history

    assert result == [
             %{role: "system", content: "You are a helpful assistant."},
             %{role: "user", content: "Hello"},
             %{role: "assistant", content: "Hi there!"}
           ]
  end
end
