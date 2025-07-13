defmodule Elita.Pat do
  @moduledoc """
  HTTP client for external Pat service
  """

  def say(prompt) do
    host = Application.get_env(:elita, :pat_host, "localhost")
    port = Application.get_env(:elita, :pat_port, 8080)
    
    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.post("http://#{host}:#{port}/", prompt) do
      {:ok, body}
    else
      {:ok, %{status_code: code}} -> {:error, "HTTP #{code}"}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end
end

