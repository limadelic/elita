defmodule Msg do
  def user(text) do
    %{role: "user", parts: [%{text: text}]}
  end

  def model(text) do
    %{role: "model", parts: [%{text: text}]}
  end

end