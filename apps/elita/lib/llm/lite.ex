defmodule Lite do
  import Compose, only: [compose: 1]
  import Snippet, only: [snip: 2]
  import Tools, only: [tools: 2]
  import Enum, only: [map: 2, find_value: 2]
  import System, only: [get_env: 1, get_env: 2]
  import Map, only: [put: 3, delete: 2]
  import List, only: [pop_at: 2]
  import Req, only: [post: 2]
  import Application, only: [get_env: 3]
  @cache_key %{type: "ephemeral"}
  def llm(%{config: config, history: history, name: agent_name} = state) do
    composed = compose(config)
    body = build(composed, history, state)

    live = fn ->
      body
      |> put(:system, sys_cache(body[:system]))
      |> put(:messages, msg_cache(body[:messages]))
      |> put(:tools, tool_cache(body[:tools]))
      |> req()
      |> resp()
    end

    result = tape(body, agent_name, live)
    {parts(result), state}
  end

  def llm(text) when is_binary(text) do
    body = request(text)
    result = tape(body, "direct", fn -> req(body) |> resp end)
    result |> text
  end

  defp tape(body, agent_name, fun),
    do: get_env(:elita, :tape_handler, &thru/3).(body, agent_name, fun)

  defp thru(_body, _agent_name, fun), do: fun.()

  defp text([%{"type" => "text", "text" => t} | _]), do: t
  defp text(other), do: other

  defp req(body), do: post(url(), opts(body))

  defp opts(body), do: [json: body] ++ req_opts()
  defp req_opts, do: [headers: headers(), connect_options: connect(), receive_timeout: 120_000]

  defp build(composed, history, state) do
    base(composed, history, state) |> add_tools(tools(composed, state))
  end

  defp base(composed, history, %{name: agent_name}) do
    text = snip(composed.content, composed[:import]) <> " Your name is #{agent_name}."
    decorate(%{model: model(), max_tokens: 4096}, text, history)
  end

  defp decorate(base, text, history) do
    base
    |> put(:system, [%{type: "text", text: text}])
    |> put(:messages, history)
  end

  defp sys_cache([%{type: "text"} = m | rest]),
    do: [put(m, :cache_control, @cache_key) | rest]

  defp sys_cache(other), do: other

  defp tool_cache([]), do: []

  defp tool_cache(tools) do
    {last, init} = pop_at(tools, -1)
    init ++ [put(last, :cache_control, @cache_key)]
  end

  defp msg_cache([]), do: []

  defp msg_cache(messages) do
    {last, init} = pop_at(messages, -1)
    init ++ [wrap_msg(last)]
  end

  defp wrap_msg(%{content: str} = m) when is_binary(str),
    do: put(m, :content, [%{type: "text", text: str, cache_control: @cache_key}])

  defp wrap_msg(%{content: blocks} = m) when is_list(blocks) do
    {block, rest} = pop_at(blocks, -1)
    put(m, :content, rest ++ [put(block, :cache_control, @cache_key)])
  end

  defp wrap_msg(msg), do: msg

  defp add_tools(base, [%{function_declarations: defs}]) do
    tools = map(defs, &schema/1)
    put(base, :tools, tools)
  end

  defp add_tools(base, _), do: base

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

  defp request(text) do
    %{model: model(), max_tokens: 4096, messages: [%{role: "user", content: text}]}
  end

  defp url, do: "#{get_env("ANTHROPIC_BASE_URL", "https://api.anthropic.com")}/v1/messages"
  defp model, do: "claude-haiku-4-5"

  defp headers, do: [{"x-api-key", token()}, {"anthropic-version", "2023-06-01"}]

  defp connect, do: ssl(get_env("NODE_EXTRA_CA_CERTS"))
  defp ssl(nil), do: []
  defp ssl(path), do: [transport_opts: [cacertfile: path]]

  defp token, do: ["ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_API_KEY"] |> find_value(&get_env/1)

  defp resp({:ok, %{status: 200, body: %{"content" => content}}}), do: content
  defp resp({:ok, %{status: code, body: body}}), do: {:error, "HTTP #{code}: #{inspect(body)}"}
  defp resp({:error, err}), do: {:error, "request failed: #{inspect(err)}"}
end
