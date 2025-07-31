defmodule Llm do
  import Jason, only: [encode!: 1]
  import String, only: [trim: 1]
  import System, only: [cmd: 2]
  import HTTPoison, only: [post: 3]
  import Resp, only: [resp: 1]

  @vertex_url "https://us-east4-aiplatform.googleapis.com/v1/projects/d-ulti-ml-ds-dev-9561/locations/us-east4/publishers/google/models/gemini-1.5-pro:generateContent"

  def llm(prompt) do
    @vertex_url
    |> post(encode!(prompt), headers())
    |> resp
  end

  defp headers do
    [
      {"Authorization", "Bearer #{token()}"},
      {"Content-Type", "application/json"}
    ]
  end


  defp token do
    {token, 0} = cmd("gcloud", ~w[auth print-access-token])
    trim(token)
  end
end
