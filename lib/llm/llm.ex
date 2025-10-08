defmodule Llm do
  import Jason, only: [encode!: 1]
  import String, only: [trim: 1]
  import System, only: [cmd: 2]
  import HTTPoison, only: [post: 3]
  import Resp, only: [resp: 1]

  @vertex_url "https://us-east5-aiplatform.googleapis.com/v1/projects/l-ulti-tf-48hours-d55d/locations/us-east5/publishers/google/models/gemini-1.5-pro:generateContent"

  def llm({prompt, %{name: name} = state}) do
    {llm(prompt, name), state}
  end

  def llm(prompt, _name \\ nil) do
    prompt
    |> encode!
    |> then(&post(@vertex_url, &1, headers()))
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
