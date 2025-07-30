defmodule PromptTest do
  use ExUnit.Case
  import Prompt, only: [prompt: 2]

  test "simple agent no header" do
    config = %{
      content: "You are a helpful assistant."
    }

    result = prompt config, []

    assert result == %{
      contents: [],
      systemInstruction: %{parts: [%{text: "You are a helpful assistant."}]}
    }
  end

  test "agent with history" do
    config = %{
      content: "You are a helpful assistant."
    }

    history = [
      %{role: "user", parts: [%{text: "Hello"}]},
      %{role: "model", parts: [%{text: "Hi there!"}]}
    ]

    result = prompt config, history

    assert result == %{
      contents: [
        %{role: "user", parts: [%{text: "Hello"}]},
        %{role: "model", parts: [%{text: "Hi there!"}]}
      ],
      systemInstruction: %{parts: [%{text: "You are a helpful assistant."}]}
    }
  end
end
