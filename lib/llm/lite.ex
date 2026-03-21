defmodule Lite do
  import Compose, only: [compose: 1]
  import Snippet, only: [snip: 2]
  import Tools, only: [tools: 2]
  import Enum, only: [map: 2]
  import System, only: [get_env: 1, get_env: 2]
  import Map, only: [put: 3, delete: 2]
  import IO, only: [write: 2]
  import Out, only: [assist: 1]
  import Ink, only: [new: 0, feed: 2]
  import Req, only: [post: 2, post!: 2]

  def llm(text) when is_binary(text) do
    req(request(text)) |> resp |> text
  end

  def llm(%{config: config, history: history} = state, mode \\ :stdout) do
    composed = compose(config)
    body = build(composed, history, state)

    case stream(body, mode, state.name) do
      {:ok, content, streamed?} ->
        state = put(state, :streamed, streamed?)
        {parts(content), state}

      {:error, reason} ->
        {parts({:error, reason}), put(state, :streamed, false)}
    end
  end

  defp text([%{"type" => "text", "text" => t} | _]), do: t
  defp text(other), do: other

  defp stream(body, mode, name) do
    emit = emit(name, mode)
    body = Map.put(body, :stream, true)

    try do
      resp =
        post!(
          url(),
          json: body,
          headers: headers(),
          connect_options: connect(),
          receive_timeout: 600_000,
          into: fn {:data, data}, {req, resp} ->
            sse = Sse.feed(data, resp.private[:elita_sse] || Sse.init(emit))
            resp = %{resp | private: Map.put(resp.private, :elita_sse, sse)}
            {:cont, {req, resp}}
          end
        )

      if resp.status != 200 do
        {:error, fault(resp)}
      else
        sse = resp.private[:elita_sse] || Sse.init(emit)
        sse = Sse.finalize(sse)

        case sse.err do
          nil -> {:ok, Sse.content(sse), mode in [:stdout, :render]}
          msg -> {:error, msg}
        end
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp fault(resp) do
    sse = resp.private[:elita_sse]

    cond do
      is_map(sse) and sse.err ->
        sse.err

      is_map(sse) and sse.raw != "" ->
        short(sse.raw)

      true ->
        "HTTP #{resp.status}"
    end
  end

  defp short(raw) do
    if String.length(raw) > 500, do: String.slice(raw, 0, 500) <> "...", else: raw
  end

  defp emit(_, :silent), do: nil

  defp emit(name, :stdout) do
    fn chunk, first? ->
      if first? do
        write(:stderr, "\e[38;5;255m✨ #{name}: \e[0m")
      end

      assist(chunk)
    end
  end

  defp emit(name, :render) do
    ink = new()

    fn chunk, first? ->
      if first? do
        write(:stderr, "\e[38;5;255m✨ #{name}:\e[0m\n")
      end

      s = Process.get(:elita_ink, ink)
      s = feed(s, chunk)
      Process.put(:elita_ink, s)
    end
  end

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
