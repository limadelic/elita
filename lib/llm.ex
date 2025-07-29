defmodule Llm do
  import Jason
  import String
  import System
  import HTTPoison
  
  @vertex_url "https://us-east4-aiplatform.googleapis.com/v1/projects/d-ulti-ml-ds-dev-9561/locations/us-east4/publishers/google/models/gemini-1.5-flash:generateContent"

  def llm message do
    @vertex_url
    |> post(body(message), headers())
    |> handle
  end
  
  defp headers do
    [
      {"Authorization", "Bearer #{token()}"},
      {"Content-Type", "application/json"}
    ]
  end
  
  defp body message do
    encode! %{
      contents: [%{
        role: "user",
        parts: [%{text: message}]
      }]
    }
  end
  
  defp handle {:ok, %HTTPoison.Response{status_code: 200, body: body}} do
    body
    |> decode
    |> extract
  end
  
  defp handle {:ok, %HTTPoison.Response{status_code: code}} do
    "HTTP #{code}"
  end
  
  defp handle {:error, %HTTPoison.Error{reason: reason}} do
    "#{reason}"
  end
  
  defp extract {:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}} | _]}} do
    text
  end
  
  defp extract _ do
    "parse failed"
  end
  
  defp token do
    {token, 0} = cmd "gcloud", ~w[auth print-access-token]
    trim token
  end
end