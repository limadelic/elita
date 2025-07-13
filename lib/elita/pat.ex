defmodule Elita.Pat do
  @url "http://localhost:8080/"

  def say(prompt) do
    HTTPoison.post(@url, prompt)
    |> response()
  end

  defp response({:ok, %{status_code: 200, body: body}}), do: {:ok, body}
  defp response({_, res}), do: {:error, inspect(res)}
end

