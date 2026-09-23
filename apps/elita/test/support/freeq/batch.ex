defmodule Freeq.Batch do
  import String, only: [split: 3, contains?: 2, trim_leading: 2, starts_with?: 2]
  import Enum, only: [join: 2, flat_map: 2]
  import List, only: [last: 1, first: 1]
  import Process, only: [get: 1, put: 2]

  def new, do: %{}

  def absorb(lines), do: flat_map(lines, &step/1)

  defp step(line), do: state() |> feed(line) |> emit()

  defp state, do: get(:freeq_batch) || new()

  defp emit({:message, line, state}) do
    put(:freeq_batch, state)
    [line]
  end

  defp emit({:pending, state}) do
    put(:freeq_batch, state)
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

  defp act(:open, _ref, body, _state), do: {:pending, start(body)}
  defp act(:skip, _ref, _body, state), do: {:pending, state}
  defp act(:close, _ref, body, state), do: shut(state, tail(body))
  defp act(:plain, ref, body, state), do: keep(mine?(state, ref), body, state)

  defp shut(%{ref: ref} = state, ref), do: {:message, assemble(state), new()}
  defp shut(state, _ref), do: {:pending, state}

  defp mine?(%{ref: ref}, ref), do: true
  defp mine?(_state, _ref), do: false

  defp keep(true, body, state), do: {:pending, add(state, text(body))}
  defp keep(false, body, state), do: {:message, body, state}

  defp start(body) do
    [src, _batch, ref, _type, chan] = split(body, " ", parts: 5)
    %{ref: trim_leading(ref, "+"), src: src, chan: chan, lines: []}
  end

  defp add(%{lines: lines} = state, text), do: %{state | lines: lines ++ [text]}

  defp tail(body), do: body |> split(" ", parts: 2) |> last() |> trim_leading("-")

  defp text(body) do
    [_src, rest] = split(body, " PRIVMSG ", parts: 2)
    rest |> split(" ", parts: 2) |> last() |> body()
  end

  defp body(":" <> text), do: text
  defp body(text), do: text

  defp assemble(%{src: src, chan: chan, lines: lines}) do
    "#{src} PRIVMSG #{chan} :#{join(lines, "\n")}"
  end

  defp ref("@batch=" <> rest), do: rest |> split(" ", parts: 2) |> first() |> tagval()
  defp ref(_line), do: ""

  defp tagval(value), do: value |> split(";", parts: 2) |> first()

  def strip("@" <> rest), do: rest |> split(" ", parts: 2) |> last()
  def strip(line), do: line
end
