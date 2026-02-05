defmodule Lite do
  import Jason, only: [encode!: 1, decode: 1]
  import HTTPoison, only: [post: 4]

  def llm(text) when is_binary(text) do
    body = request(text) |> encode!
    post(url(), body, headers(), opts()) |> resp
  end

  defp request(text) do
    %{
      model: model(),
      max_tokens: 4096,
      messages: [%{role: "user", content: text}]
    }
  end

  defp url do
    base = System.get_env("ANTHROPIC_BASE_URL", "https://api.anthropic.com")
    "#{base}/v1/messages"
  end

  defp model do
    System.get_env("ANTHROPIC_MODEL", "claude-sonnet-4-5")
  end

  defp headers do
    [
      {"x-api-key", token()},
      {"anthropic-version", "2023-06-01"},
      {"content-type", "application/json"}
    ]
  end

  defp opts do
    case System.get_env("NODE_EXTRA_CA_CERTS") do
      nil -> []
      path -> [ssl: [cacertfile: path]]
    end
  end

  defp token do
    System.get_env("ANTHROPIC_AUTH_TOKEN") ||
      System.get_env("ANTHROPIC_API_KEY") ||
      raise "Missing ANTHROPIC_AUTH_TOKEN or ANTHROPIC_API_KEY"
  end

  defp resp({:ok, %{status_code: 200, body: body}}) do
    case decode(body) do
      {:ok, %{"content" => [%{"text" => text} | _]}} -> text
      {:ok, other} -> {:error, "unexpected response: #{inspect(other)}"}
      {:error, err} -> {:error, "json parse: #{inspect(err)}"}
    end
  end

  defp resp({:ok, %{status_code: code, body: body}}) do
    {:error, "HTTP #{code}: #{body}"}
  end

  defp resp({:error, %{reason: reason}}) do
    {:error, "request failed: #{reason}"}
  end
end
