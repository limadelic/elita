defmodule Prompt do
  import Tools, only: [tools: 1]
  import Snippet, only: [snip: 2]

  def prompt(config, history) do
    content = snip(config.content, config[:import])
    
    IO.puts("=== PROMPT CONTENT ===")
    IO.puts(content)
    IO.puts("=== END PROMPT ===")
    
    %{
      contents: history,
      systemInstruction: %{parts: [%{text: content}]},
      tools: tools(config)
    }
  end
end
