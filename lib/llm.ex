defmodule Llm do
  import Jason, only: [encode!: 1, decode: 1]
  import String, only: [trim: 1]
  import System, only: [cmd: 2]
  import HTTPoison, only: [post: 3]
  
  @vertex_url "https://us-east4-aiplatform.googleapis.com/v1/projects/d-ulti-ml-ds-dev-9561/locations/us-east4/publishers/google/models/gemini-1.5-pro:generateContent"


  def llm(message, tools \\ []) do
    @vertex_url
    |> post(body(message, tools), headers())
    |> handle
  end

  
  defp headers do
    [
      {"Authorization", "Bearer #{token()}"},
      {"Content-Type", "application/json"}
    ]
  end
  
  defp body(message, []) do
    encode! %{
      contents: [%{
        role: "user",
        parts: [%{text: message}]
      }]
    }
  end

  defp body(message, tools) when tools != [] do
    encode! %{
      contents: [%{
        role: "user",
        parts: [%{text: message}]
      }],
      tools: tools
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
  
  defp extract {:ok, response} do
    case response do
      %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}} | _]} ->
        {:text, text}
      %{"candidates" => [%{"content" => %{"parts" => [%{"functionCall" => function_call}]}} | _]} ->
        {:tool_call, function_call}
      _ ->
        {:error, "parse failed"}
    end
  end
  
  defp extract _error do
    {:error, "parse failed"}
  end
  
  defp token do
    {token, 0} = cmd "gcloud", ~w[auth print-access-token]
    trim token
  end
end