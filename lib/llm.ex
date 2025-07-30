defmodule Llm do
  import Jason, only: [encode!: 1, decode: 1]
  import String, only: [trim: 1]
  import System, only: [cmd: 2]
  import HTTPoison, only: [post: 3]

  @vertex_url "https://us-east4-aiplatform.googleapis.com/v1/projects/d-ulti-ml-ds-dev-9561/locations/us-east4/publishers/google/models/gemini-1.5-pro:generateContent"

  def llm(prompt) do
    @vertex_url
    |> post(encode!(prompt), headers())
    |> handle
  end

  defp headers do
    [
      {"Authorization", "Bearer #{token()}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp handle({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    body
    |> decode
    |> msg
  end

  defp handle({:ok, %HTTPoison.Response{status_code: code}}) do
    "HTTP #{code}"
  end

  defp handle({:error, %HTTPoison.Error{reason: reason}}) do
    "#{reason}"
  end

  defp msg({:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}} | _]}}) do
    text
  end

  defp msg(_) do
    "parse failed"
  end

  defp token do
    {token, 0} = cmd("gcloud", ~w[auth print-access-token])
    trim(token)
  end
end
