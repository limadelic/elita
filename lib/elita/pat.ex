defmodule Elita.Pat do
  @url "http://192.168.1.22:3001/"

  def say(prompt) do
    HTTPoison.post(@url, prompt, [], timeout: 30_000, recv_timeout: 30_000)
    |> response()
  end

  defp response({:ok, %{status_code: 200, body: body}}), do: {:ok, body}
  defp response({_, res}), do: {:error, inspect(res)}
end

