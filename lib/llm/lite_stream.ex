defmodule Lite.Stream do
  @moduledoc false

  import IO, only: [write: 2]
  import Out, only: [assist: 1]
  import Ink, only: [new: 0]
  import Req, only: [post!: 2]
  import Log, only: [label: 2]

  def run(body, mode, name, conn) do
    body = Map.put(body, :stream, true)
    opts = sse_opts(mode, name)
    url = Keyword.fetch!(conn, :url)
    headers = Keyword.fetch!(conn, :headers)
    connect = Keyword.fetch!(conn, :connect)

    try do
      resp =
        post!(
          url,
          json: body,
          headers: headers,
          connect_options: connect,
          receive_timeout: 600_000,
          into: fn {:data, data}, {req, resp} ->
            sse = Sse.feed(data, resp.private[:elita_sse] || Sse.init(opts))
            resp = %{resp | private: Map.put(resp.private, :elita_sse, sse)}
            {:cont, {req, resp}}
          end
        )

      if resp.status != 200 do
        {:error, fault(resp)}
      else
        sse = resp.private[:elita_sse] || Sse.init(opts)
        sse = Sse.finalize(sse)

        case sse.err do
          nil ->
            ink = ink_after(mode, sse)
            {:ok, Sse.content(sse), mode in [:stdout, :render], ink}

          msg ->
            {:error, msg}
        end
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp ink_after(:render, %{ink: ink}) when is_map(ink), do: ink
  defp ink_after(_, _), do: nil

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

  defp sse_opts(:silent, _) do
    [emit: nil, ink: :none, name: nil]
  end

  defp sse_opts(:stdout, name) do
    [emit: emit_stdout(name), ink: :none, name: nil]
  end

  defp sse_opts(:render, name) do
    [emit: nil, ink: new(), name: name]
  end

  defp emit_stdout(name) do
    fn chunk, first? ->
      if first? do
        write(:stderr, label(name, :stdout))
      end

      assist(chunk)
    end
  end
end
