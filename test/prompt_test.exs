defmodule PromptTest do
  use ExUnit.Case
  import Prompt, only: [prompt: 2]

  test "simple agent no header" do

    config = %{
      content: "You are a helpful assistant."
    }

    result = prompt con

    assert result == """
           You are a helpful assistant.

           History:

           """
  end
end
