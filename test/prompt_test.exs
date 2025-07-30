defmodule PromptTest do
  use ExUnit.Case
  import Prompt, only: [prompt1: 2]

  test "simple agent no header" do
    config = %{
      content: "You are a helpful assistant."
    }

    result = prompt1 config, []

    assert result == [
             %{
               role: "system",
               content: "You are a helpful assistant."
             }
           ]
  end
end
