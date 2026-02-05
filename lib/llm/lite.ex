defmodule Lite do
  import Compose, only: [compose: 1]
  import Snippet, only: [snip: 2]
  import Tools, only: [tools: 2]
  import Enum, only: [map: 2]
  import System, only: [get_env: 1, get_env: 2]
  import Map, only: [put: 3, delete: 2]
  import Req, only: [post: 2]

  def llm(%{config: config, history: history} = state) do
    composed = compose(config)
    body = build(composed, history, state)
    result = req(body) |> resp
    {parts(result), state}
  end

  def llm(text) when is_binary(text) do
    req(request(text)) |> resp |> text
  end

  defp text([%{"type" => "text", "text" => t} | _]), do: t
  defp text(other), do: other

  defp req(body) do
    post(url(), json: body, headers: headers(), connect_options: connect())
  end

  defp build(composed, history, state) do
    base = %{
      model: model(),
      max_tokens: 4096,
      system: snip(composed.content, composed[:import]),
      messages: history
    }
    add_tools(base, tools(composed, state))
  end

  defp add_tools(base, [%{function_declarations: defs}]) do
    put(base, :tools, map(defs, &schema/1))
  end
  defp add_tools(base, _), do: base

  defp schema(%{parameters: params} = tool) do
    tool |> delete(:parameters) |> put(:input_schema, params)
  end
  defp schema(tool), do: put(tool, :input_schema, %{type: "object"})

  defp parts(list) when is_list(list), do: map(list, &part/1)
  defp parts({:error, _} = err), do: err

  defp part(%{"type" => "text", "text" => text}), do: %{"text" => text}
  defp part(%{"type" => "tool_use", "id" => id, "name" => name, "input" => input}) do
    %{"tool_use" => %{"id" => id, "name" => name, "input" => input}}
  end
  defp part(other), do: other

  defp request(text) do
    %{
      model: model(),
      max_tokens: 4096,
      messages: [%{role: "user", content: text}]
    }
  end

  defp url, do: "#{get_env("ANTHROPIC_BASE_URL", "https://api.anthropic.com")}/v1/messages"

  defp model, do: get_env("ANTHROPIC_MODEL", "claude-haiku-4-5")

  defp headers do
    [
      {"x-api-key", token()},
      {"anthropic-version", "2023-06-01"}
    ]
  end

  defp connect, do: ssl(get_env("NODE_EXTRA_CA_CERTS"))
  defp ssl(nil), do: []
  defp ssl(path), do: [transport_opts: [cacertfile: path]]

  defp token, do: get_env("ANTHROPIC_AUTH_TOKEN") || get_env("ANTHROPIC_API_KEY")

  defp resp({:ok, %{status: 200, body: %{"content" => content}}}), do: content
  defp resp({:ok, %{status: code, body: body}}), do: {:error, "HTTP #{code}: #{inspect(body)}"}
  defp resp({:error, err}), do: {:error, "request failed: #{inspect(err)}"}
end
