defmodule Lite do
  import Application, only: [get_env: 2]
  import Compose, only: [compose: 1]
  import Snippet, only: [snip: 2]
  import Tools, only: [tools: 2]
  import Enum, only: [map: 2]
  import Map, only: [put: 3, delete: 2, get: 2]
  import List, only: [pop_at: 2]
  import Req, only: [post: 2]
  import Tape, only: [handle: 4]
  import Miss, only: [opts: 1]
  import Meter, only: [spend: 2]
  @cache_key %{type: "ephemeral"}
  def llm(%{config: config, history: history, name: agent_name} = state) do
    composed = compose(config)
    body = build(composed, history, state)
    result = tape(body, agent_name, state)
    {parts(result), state}
  end

  defp tape(body, name, state) do
    cfg = opts(get_env(:elita, :tape_on_miss))
    payload = [tape: state[:tape], live: state[:live]] ++ cfg
    handle(body, name, fn -> req(body) |> resp end, payload)
  end

  defp req(body), do: post(url(), payload(body))

  defp payload(body), do: [json: body] ++ settings()
  defp settings, do: [headers: headers(), connect_options: connect(), receive_timeout: 120_000]

  defp build(composed, history, state) do
    base(composed, history, state) |> equip(tools(composed, state))
  end

  defp base(composed, history, %{name: agent_name}) do
    text = snip(composed.content, composed[:import]) <> " Your name is #{agent_name}."
    decorate(%{model: model(), max_tokens: 4096}, text, history)
  end

  defp decorate(base, text, history) do
    base
    |> put(:system, [%{type: "text", text: text, cache_control: @cache_key}])
    |> put(:messages, history)
  end

  defp equip(base, [%{function_declarations: defs}]) do
    tools = map(defs, &schema/1)
    put(base, :tools, cache(tools))
  end

  defp equip(base, _), do: base

  defp cache(tools) do
    {last, init} = pop_at(tools, -1)
    mark(last, init, tools)
  end

  defp mark(nil, _init, tools), do: tools
  defp mark(last, init, _tools), do: init ++ [put(last, :cache_control, @cache_key)]

  defp schema(%{parameters: params} = tool),
    do: tool |> delete(:parameters) |> put(:input_schema, params)

  defp schema(tool),
    do: put(tool, :input_schema, %{type: "object"})

  defp parts(list) when is_list(list), do: map(list, &part/1)
  defp parts({:error, _} = err), do: err
  defp part(%{"type" => "text", "text" => text}), do: %{"text" => text}

  defp part(%{"type" => "tool_use", "id" => id, "name" => name, "input" => input}),
    do: %{"tool_use" => %{"id" => id, "name" => name, "input" => input}}

  defp part(other), do: other

  defp url, do: "#{get_env(:elita, :base_url)}/v1/messages"
  defp model, do: "claude-haiku-4-5"

  defp headers, do: [{"x-api-key", token()}, {"anthropic-version", "2023-06-01"}]

  defp connect, do: ssl(get_env(:elita, :ca_certs))
  defp ssl(nil), do: []
  defp ssl(path), do: [transport_opts: [cacertfile: path]]

  defp token, do: get_env(:elita, :auth_token)

  defp resp({:ok, %{status: 200, body: body}}), do: respond(body)
  defp resp({:ok, %{status: code, body: body}}), do: {:error, "HTTP #{code}: #{inspect(body)}"}
  defp resp({:error, err}), do: {:error, "request failed: #{inspect(err)}"}

  defp respond(%{"content" => content} = body) do
    spend(:api, get(body, "usage"))
    content
  end
end
