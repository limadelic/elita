defmodule Msg do
  def user(text) do
    %{role: "user", content: text}
  end

  def assistant(text) do
    %{role: "assistant", content: text}
  end

  def tool_use(id, name, input) do
    %{role: "assistant", content: [%{type: "tool_use", id: id, name: name, input: input}]}
  end

  def tool_result(id, content) do
    %{role: "user", content: [%{type: "tool_result", tool_use_id: id, content: content}]}
  end
end
