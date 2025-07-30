defmodule Prompt do
  def prompt(%{content: content}, history) do
    %{
      contents: history,
      systemInstruction: %{parts: [%{text: content}]}
    }
  end
end
