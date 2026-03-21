defmodule Sse do
  @moduledoc false

  import Jason, only: [decode: 1]
  import Map, only: [put: 3]
  import IO, only: [write: 2]
  import Log, only: [label: 2]

  def init(opts) when is_list(opts) do
    if Keyword.keyword?(opts) do
      init_from_kw(opts)
    else
      raise ArgumentError, "expected keyword list"
    end
  end

  def init(nil), do: init_from_kw(emit: nil, ink: :none, name: nil)

  def init(emit) when is_function(emit, 2) do
    init_from_kw(emit: emit, ink: :none, name: nil)
  end

  defp init_from_kw(opts) do
    emit = Keyword.get(opts, :emit)
    ink = Keyword.get(opts, :ink, :none)
    name = Keyword.get(opts, :name)

    %{
      buffer: "",
      blocks: %{},
      emit: emit,
      first: true,
      err: nil,
      raw: "",
      ink: ink,
      name: name
    }
  end

  def feed(data, state) do
    state = %{state | raw: state.raw <> data}
    lines(state.buffer <> data, %{state | buffer: ""})
  end

  def finalize(state) do
    if state.buffer != "" do
      line(state.buffer, %{state | buffer: ""})
    else
      state
    end
  end

  def content(state) do
    state.blocks
    |> Enum.sort_by(fn {i, _} -> i end)
    |> Enum.map(fn {_, b} -> block(b) end)
    |> Enum.reject(&is_nil/1)
  end

  defp block(%{kind: :text, text: t}), do: %{"type" => "text", "text" => t}

  defp block(%{kind: :tool, id: id, name: name, input: input}) do
    %{"type" => "tool_use", "id" => id, "name" => name, "input" => input}
  end

  defp block(_), do: nil

  defp lines(buffer, state) do
    case String.split(buffer, "\n", parts: 2) do
      [line, rest] ->
        state = line(line, state)
        lines(rest, state)

      [buf] ->
        %{state | buffer: buf}
    end
  end

  defp line("", state), do: state
  defp line("event: " <> _, state), do: state
  defp line("data: " <> json, state), do: data(json, state)
  defp line(_, state), do: state

  defp data(json, state) do
    case decode(json) do
      {:ok, ev} ->
        event(ev, state)

      {:error, _} ->
        put_sse_err(state, "invalid JSON in SSE data line")
    end
  end

  defp event(%{"type" => "error", "error" => err}, state) do
    msg = err["message"] || inspect(err)
    %{state | err: msg}
  end

  defp event(%{"type" => "content_block_start", "index" => i, "content_block" => cb}, state) do
    block =
      case cb["type"] do
        "text" -> %{kind: :text, text: ""}
        "tool_use" -> %{kind: :tool, id: cb["id"], name: cb["name"], json: ""}
        _ -> %{kind: :skip}
      end

    put_in(state.blocks[i], block)
  end

  defp event(%{"type" => "content_block_delta", "index" => i, "delta" => d}, state) do
    case d["type"] do
      "text_delta" ->
        t = d["text"] || ""
        blk = Map.get(state.blocks, i) || %{kind: :text, text: ""}
        prev = Map.get(blk, :text) || ""
        blk = blk |> put(:kind, :text) |> put(:text, prev <> t)
        state = put_in(state.blocks[i], blk)
        drain(state, t)

      "input_json_delta" ->
        pj = d["partial_json"] || ""
        blk = Map.get(state.blocks, i) || %{kind: :tool, json: ""}
        prev = Map.get(blk, :json) || ""
        blk = blk |> put(:kind, :tool) |> put(:json, prev <> pj)
        put_in(state.blocks[i], blk)

      _ ->
        state
    end
  end

  defp event(%{"type" => "content_block_stop", "index" => i}, state) do
    case state.blocks[i] do
      %{kind: :tool, json: j} = b when j != "" ->
        input =
          case decode(j) do
            {:ok, parsed} -> parsed
            _ -> %{}
          end

        put_in(state.blocks[i], put(b, :input, input))

      %{kind: :tool} = b ->
        put_in(state.blocks[i], put(b, :input, %{}))

      _ ->
        state
    end
  end

  defp event(_, state), do: state

  defp put_sse_err(%{err: err} = s, _) when not is_nil(err), do: s
  defp put_sse_err(s, msg), do: %{s | err: msg}

  defp drain(%{ink: ink} = s, t) when is_map(ink) do
    if s.first do
      write(:stderr, label(s.name, :render_open))
    end

    ink = Ink.feed(ink, t)
    %{s | first: false, ink: ink}
  end

  defp drain(%{emit: emit, first: first} = s, t) when not is_nil(emit) do
    emit.(t, first)
    %{s | first: false}
  end

  defp drain(s, _), do: s
end
