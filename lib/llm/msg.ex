defmodule Msg do
  def user(text) do
    %{role: "user", parts: [%{text: text}]}
  end

  def model(text) do
    %{role: "model", parts: [%{text: text}]}
  end

  def function_call(name, args, id \\ nil) do
    %{role: "model", parts: [%{functionCall: %{name: name, args: args, id: id}}]}
  end

  def function_response(name, response, id \\ nil) do
    %{role: "user", parts: [%{functionResponse: %{name: name, response: %{content: response}, id: id}}]}
  end
end