defmodule Msg do
  def user(text) do
    %{role: "user", parts: [%{text: text}]}
  end

  def model(text) do
    %{role: "model", parts: [%{text: text}]}
  end

  def function_call(name, args) do
    %{role: "model", parts: [%{functionCall: %{name: name, args: args}}]}
  end

  def function_response(name, response) do
    %{role: "user", parts: [%{functionResponse: %{name: name, response: response}}]}
  end
end