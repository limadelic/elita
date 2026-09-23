defmodule Freeq.Batch do
  import String, only: [split: 3, contains?: 2, trim_leading: 2, starts_with?: 2]
  import Enum, only: [join: 2, flat_map: 2]
  import List, only: [last: 1, first: 1]
  import Map, only: [put: 3, delete: 2, has_key?: 2, fetch!: 2]

  def new, do: %{}

  def absorb(lines), do: flat_map(lines, &step/1)

  defp step(line), do: state() |> feed(line) |> emit()

  defp state, do: Process.get(:freeq_batch) || new()

  defp emit({:message, line, state}) do
    Process.put(:freeq_batch, state)
    [line]
  end

  defp emit({:pending, state}) do
    Process.put(:freeq_batch, state)
    []
  end

  def feed(state, line) do
    body = strip(line)
    act(kind(body), ref(line), body, state)
  end

  defp kind(body), do: sort(contains?(body, " BATCH +"), starts_with?(body, "BATCH -"), body)

  defp sort(true, _close, body), do: multi(contains?(body, " draft/multiline "))
  defp sort(_open, true, _body), do: :close
  defp sort(_open, _close, _body), do: :plain

  defp multi(true), do: :open
  defp multi(false), do: :skip

  defp act(:open, _ref, body, state), do: {:pending, open(state, body)}
  defp act(:skip, _ref, _body, state), do: {:pending, state}
  defp act(:close, _ref, body, state), do: shut(state, tail(body))
  defp act(:plain, ref, body, state), do: keep(has_key?(state, ref), ref, body, state)

  defp open(state, body) do
    [src, _batch, ref, _type, chan] = split(body, " ", parts: 5)
    put(state, trim_leading(ref, "+"), %{src: src, chan: chan, lines: []})
  end

  defp shut(state, ref), do: close(has_key?(state, ref), state, ref)

  defp close(true, state, ref), do: {:message, assemble(fetch!(state, ref)), delete(state, ref)}
  defp close(false, state, _ref), do: {:pending, state}

  defp keep(true, ref, body, state), do: {:pending, add(state, ref, text(body))}
  defp keep(false, _ref, body, state), do: {:message, body, state}

  defp add(state, ref, text) do
    batch = fetch!(state, ref)
    put(state, ref, %{batch | lines: batch.lines ++ [text]})
  end

  defp tail(body), do: body |> split(" ", parts: 2) |> last() |> trim_leading("-")

  defp text(body) do
    [_src, rest] = split(body, " PRIVMSG ", parts: 2)
    rest |> split(" ", parts: 2) |> last() |> payload()
  end

  defp payload(":" <> text), do: text
  defp payload(text), do: text

  defp assemble(%{src: src, chan: chan, lines: lines}) do
    "#{src} PRIVMSG #{chan} :#{join(lines, "\n")}"
  end

  defp ref("@batch=" <> rest), do: rest |> split(" ", parts: 2) |> first() |> tagval()
  defp ref(_line), do: ""

  defp tagval(value), do: value |> split(";", parts: 2) |> first()

  def strip("@" <> rest), do: rest |> split(" ", parts: 2) |> last()
  def strip(line), do: line
end
