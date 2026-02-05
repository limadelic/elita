defmodule Lite do
  import Jason, only: [encode!: 1, decode: 1]
  import HTTPoison, only: [post: 4]
  import Compose, only: [compose: 1]
  import Enum, only: [map: 2]
  import System, only: [get_env: 1, get_env: 2]

  def llm(%{config: config, history: history} = state) do
    composed = compose(config)
    body = build(composed.content, history) |> encode!
    result = post(url(), body, headers(), opts()) |> resp
    {parts(result), state}
  end

  def llm(text) when is_binary(text) do
    body = request(text) |> encode!
    post(url(), body, headers(), opts()) |> resp
  end

  defp build(system, history) do
    %{
      model: model(),
      max_tokens: 4096,
      system: system,
      messages: map(history, &convert/1)
    }
  end

  defp convert(%{role: "user", parts: [%{text: text} | _]}), do: %{role: "user", content: text}
  defp convert(%{role: "model", parts: [%{text: text} | _]}), do: %{role: "assistant", content: text}
  defp convert(msg), do: msg

  defp parts(text) when is_binary(text), do: [%{"text" => text}]
  defp parts({:error, _} = err), do: err

  defp request(text) do
    %{
      model: model(),
      max_tokens: 4096,
      messages: [%{role: "user", content: text}]
    }
  end

  defp url, do: "#{get_env("ANTHROPIC_BASE_URL", "https://api.anthropic.com")}/v1/messages"

  defp model, do: get_env("ANTHROPIC_MODEL", "claude-sonnet-4-5")

  defp headers do
    [
      {"x-api-key", token()},
      {"anthropic-version", "2023-06-01"},
      {"content-type", "application/json"}
    ]
  end

  defp opts, do: ssl(get_env("NODE_EXTRA_CA_CERTS")) ++ [recv_timeout: 120_000]
  defp ssl(nil), do: []
  defp ssl(path), do: [ssl: [cacertfile: path]]

  defp token, do: get_env("ANTHROPIC_AUTH_TOKEN") || get_env("ANTHROPIC_API_KEY")

  defp resp({:ok, %{status_code: 200, body: body}}), do: parse(decode(body))
  defp resp({:ok, %{status_code: code, body: body}}), do: {:error, "HTTP #{code}: #{body}"}
  defp resp({:error, %{reason: reason}}), do: {:error, "request failed: #{reason}"}

  defp parse({:ok, %{"content" => [%{"text" => text} | _]}}), do: text
  defp parse({:ok, other}), do: {:error, "unexpected response: #{inspect(other)}"}
  defp parse({:error, err}), do: {:error, "json parse: #{inspect(err)}"}
end
