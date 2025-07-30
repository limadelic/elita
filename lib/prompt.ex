defmodule Prompt do
  import Def, only: [tools: 1]

  def prompt(config, history) do
    %{
      contents: history,
      systemInstruction: %{parts: [%{text: config.content}]},
      tools: tools(config)
    }
  end
end
