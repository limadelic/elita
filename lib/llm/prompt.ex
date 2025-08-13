defmodule Prompt do
  import Tools, only: [tools: 1]
  import Snippet, only: [snip: 2]

  def prompt(config, history) do
    content = snip(config.content, config[:import])
    
    %{
      contents: history,
      systemInstruction: %{parts: [%{text: content}]},
      tools: tools(config)
    }
  end
end
