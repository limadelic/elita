defmodule Prompt do
  import Tools, only: [tools: 1]
  import Snippet, only: [snip: 2]
  import Compose, only: [compose: 1]

  def prompt(configs, history) do
    composed = compose(configs)
    content = snip(composed.content, composed[:import])
    
    %{
      contents: history,
      systemInstruction: %{parts: [%{text: content}]},
      tools: tools(composed)
    }
  end

  def prompt(state) do
    {prompt(state.config, state.history), state}
  end
end
