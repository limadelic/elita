defmodule Llm do
  def llm(message) when is_binary(message) do
    case HTTPoison.post("http://192.168.1.22:3001", message) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        "HTTP #{status_code}"
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        "#{reason}"
    end
  end
end