defmodule Msg do
  def user(text) do
    %{role: "user", parts: [%{text: text}]}
  end

  def model(text) do
    %{role: "model", parts: [%{text: text}]}
  end

  def function(text) do
    %{role: "user", parts: [%{text: "Function result: #{text}"}]}
  end
end