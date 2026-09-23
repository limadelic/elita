defmodule Freeq.Inbound do
  def route("BATCH +" <> rest, state) do
    [id, type, target | _] = String.split(rest)
    batches = Map.put(state.batches, id, {type, target, []})
    {:noreply, %{state | batches: batches}}
  end

  def route("BATCH -" <> id, %{batches: batches} = state, handler) do
    key = String.trim(id)
    case Map.pop(batches, key) do
      {{_type, _target, lines}, rest} ->
        body = Freeq.Batch.assemble(Enum.reverse(lines))
        handler.(":" <> body, %{state | batches: rest})
      {nil, _rest} ->
        {:noreply, state}
    end
  end

  def route("@batch=" <> rest, %{batches: batches} = state, handler)
      when map_size(batches) > 0 do
    [bid, msg] = String.split(rest, " ", parts: 2)
    batch_id = String.split(bid, ";") |> List.first()
    accumulate(batch_id, msg, state, handler)
  end

  def route(str, state, _handler), do: {:continue, str, state}

  defp accumulate(batch_id, msg, %{batches: batches} = state, _handler) do
    case Map.get(batches, batch_id) do
      {type, target, lines} ->
        body = extract_body(msg)
        new_lines = [body | lines]
        new_batches = Map.put(batches, batch_id, {type, target, new_lines})
        {:noreply, %{state | batches: new_batches}}
      nil ->
        {:continue, "@batch=" <> msg, state}
    end
  end

  defp extract_body(msg) do
    case String.split(msg, " :", parts: 2) do
      [_prefix, body] -> body
      _ -> ""
    end
  end
end
