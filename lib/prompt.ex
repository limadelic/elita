defmodule Prompt do
  import Tools, only: [defs: 1]

  def prompt(config, history) do
    %{
      contents: history,
      systemInstruction: %{parts: [%{text: config.content}]},
      tools: defs(config)
    }
  end
end
