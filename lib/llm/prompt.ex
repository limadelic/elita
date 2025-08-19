defmodule Prompt do
  import Tools, only: [tools: 2]
  import Compose, only: [compose: 1]
  import Snippet, only: [snip: 2]

  def prompt(%{config: configs, history: history} = state) do
    composed = compose(configs)
    content = snip(composed.content, composed[:import])

    prompt = %{
      contents: history,
      systemInstruction: %{parts: [%{text: content}]},
      tools: tools(composed, state)
    }

    {prompt, state}
  end
end
