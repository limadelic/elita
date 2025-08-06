defmodule Prompt do
  import Tools, only: [tools: 1]
  import Snippet, only: [execute: 2]

  def prompt(config, history) do
    content = execute(config.content, config[:import])
    
    %{
      contents: history,
      systemInstruction: %{parts: [%{text: content}]},
      tools: tools(config)
    }
  end
end
