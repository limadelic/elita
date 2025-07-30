defmodule Prompt do
  def prompt(%{content: content}, history) do
    [
      %{role: "system", content: content}
      | history
    ]
  end
end
