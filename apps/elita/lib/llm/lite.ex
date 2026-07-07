defmodule Lite do
  import Application, only: [get_env: 3]
  import Compose, only: [compose: 1]
  import Enum, only: [map: 2]
  import Map, only: [put: 3, delete: 2]
  import Snippet, only: [snip: 2]
  import Tools, only: [tools: 2]

  alias Lite.Client
  alias Lite.Parts

  @cache_key %{type: "ephemeral"}
  def llm(%{config: config, history: history, name: agent_name} = state) do
    composed = compose(config)
    body = build(composed, history, state)
    result = tape(body, agent_name, fn -> Client.req(body) |> Client.resp() end)
    {Parts.parse(result), state}
  end

  def llm(text) when is_binary(text) do
    body = request(text)
    result = tape(body, "direct", fn -> Client.req(body) |> Client.resp() end)
    result |> Parts.text()
  end

  defp tape(body, agent_name, fun),
    do: get_env(:elita, :tape_handler, &thru/3).(body, agent_name, fun)

  defp thru(_body, _agent_name, fun), do: fun.()

  defp build(composed, history, state) do
    base(composed, history, state) |> add_tools(tools(composed, state))
  end

  defp base(composed, history, %{name: agent_name}) do
    text = prompt(composed, agent_name)

    %{model: "claude-haiku-4-5", max_tokens: 4096}
    |> put(:system, [%{type: "text", text: text, cache_control: @cache_key}])
    |> put(:messages, history)
  end

  defp prompt(composed, agent_name) do
    snip(composed.content, composed[:import]) <> " Your name is #{agent_name}."
  end

  defp add_tools(base, [%{function_declarations: defs}]) do
    tools = map(defs, &schema/1)
    put(base, :tools, cache(tools))
  end

  defp add_tools(base, _), do: base

  defp cache(tools) do
    {last, init} = List.pop_at(tools, -1)
    apply_cache(last, init, tools)
  end

  defp apply_cache(nil, _init, tools), do: tools

  defp apply_cache(last, init, _tools),
    do: init ++ [put(last, :cache_control, @cache_key)]

  defp schema(%{parameters: params} = tool),
    do: tool |> delete(:parameters) |> put(:input_schema, params)

  defp schema(tool), do: put(tool, :input_schema, %{type: "object"})

  defp request(text) do
    %{
      model: "claude-haiku-4-5",
      max_tokens: 4096,
      messages: [%{role: "user", content: text}]
    }
  end
end
