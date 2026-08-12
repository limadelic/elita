defmodule Matrix.Ansi.Csi do
  import Elui.Buffer, only: [put: 4, reset: 1]
  import Elui.Buffer.Cell, only: [empty: 0]
  import Enum, only: [any?: 2, reduce: 3]
  import Regex, only: [run: 2]

  import String,
    only: [last: 1, ends_with?: 2, starts_with?: 2, to_integer: 1]

  def done?(s) when is_binary(s) do
    any?([check(s), snap(s)], & &1)
  end

  def handle(<<"2J"::binary, _::binary>>, state) do
    %{state | buffer: reset(state.buffer), cursor: {0, 0}}
  end

  def handle(<<"K"::binary, _::binary>>, state) do
    erase(state)
  end

  def handle(rest, state) do
    chain(run(~r/^(\d{1,3});(\d{1,3})H/, rest), rest, state)
  end

  defp chain([_ | _] = m, _rest, state), do: locate(state, m)
  defp chain(nil, rest, state), do: chain2(run(~r/^(\d{1,3})H/, rest), rest, state)

  defp chain2([_ | _] = m, _rest, state), do: position(state, m)
  defp chain2(nil, rest, state), do: chain3(run(~r/^(\d{1,3})(A|B|C|D|G)/, rest), state)

  defp chain3([_ | _] = m, state), do: shift(state, m)
  defp chain3(nil, state), do: state

  defp locate(state, [_, r, c]) do
    %{state | cursor: {to_integer(c) - 1, to_integer(r) - 1}}
  end

  defp position(state, [_, c]) do
    %{state | cursor: {to_integer(c) - 1, 0}}
  end

  defp shift(state, [_, n, "A"]) do
    {x, y} = state.cursor
    %{state | cursor: {x, max(y - to_integer(n), 0)}}
  end

  defp shift(state, [_, n, "B"]) do
    {x, y} = state.cursor
    %{state | cursor: {x, min(y + to_integer(n), state.height - 1)}}
  end

  defp shift(state, [_, n, "C"]) do
    {x, y} = state.cursor
    %{state | cursor: {min(x + to_integer(n), state.width - 1), y}}
  end

  defp shift(state, [_, n, "D"]) do
    {x, y} = state.cursor
    %{state | cursor: {max(x - to_integer(n), 0), y}}
  end

  defp shift(state, [_, n, "G"]) do
    {_, y} = state.cursor
    %{state | cursor: {to_integer(n) - 1, y}}
  end

  defp erase(%{cursor: {x, y}, width: w, buffer: b} = s) do
    nb = reduce(x..(w - 1), b, fn xp, buf -> put(buf, xp, y, empty()) end)
    %{s | buffer: nb}
  end

  defp check(s) when is_binary(s) do
    [csi(s), term(s), bell(s)] |> any?(& &1)
  end

  defp csi(s), do: last(s) in ["A", "B", "C", "D", "H", "J", "K", "m", "h", "l", "r", "f", "G"]
  defp term(s), do: ends_with?(s, "\e\\")
  defp bell(s), do: ends_with?(s, "\x07")

  defp snap(s) when is_binary(s) do
    [saved(s), restored(s), g0(s), g1(s), mode(s)] |> any?(& &1)
  end

  defp saved(s), do: begin(s, "\e7")
  defp restored(s), do: begin(s, "\e8")
  defp g0(s), do: begin(s, "\e(")
  defp g1(s), do: begin(s, "\e)")
  defp mode(s), do: s =~ ~r/\e\[[0-9;]*[?][0-9;]*[hlm]$/

  defp begin(s, p) when byte_size(s) > 2, do: starts_with?(s, p)
  defp begin(_, _), do: false
end
