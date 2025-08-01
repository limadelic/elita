defmodule Llm do
  import Jason, only: [encode!: 1]
  import String, only: [trim: 1]
  import System, only: [cmd: 2]
  import HTTPoison, only: [post: 3]
  import Resp, only: [resp: 1]

  @vertex_url "https://us-east4-aiplatform.googleapis.com/v1/projects/d-ulti-ml-ds-dev-9561/locations/us-east4/publishers/google/models/gemini-1.5-pro:generateContent"

  def llm(prompt) do
    IO.puts("LLM PROMPT: #{inspect(prompt)}")
    result = @vertex_url
    |> post(encode!(prompt), headers())
    |> resp
    IO.puts("LLM RESULT: #{inspect(result)}")
    result
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
