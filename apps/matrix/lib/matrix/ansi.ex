defmodule Matrix.Ansi do
  import Elui.Buffer, only: [empty: 1, put: 4, to_lines: 1]
  import Elui.Buffer.Cell, only: [new: 1]
  import Elui.Layout.Rect, only: [new: 4]
  import String, only: [graphemes: 1]
  import Enum, only: [reduce: 3]
  import Matrix.Ansi.Csi, only: [done?: 1, handle: 2]

  defstruct buffer: nil,
            cursor: {0, 0},
            pending: nil,
            width: 80,
            height: 24,
            updates: []

  def init(width \\ 80, height \\ 24) do
    build(width, height)
  end

  defp build(w, h) do
    buf = empty(new(0, 0, w, h))
    %__MODULE__{width: w, height: h, buffer: buf, updates: []}
  end

  def feed(%__MODULE__{} = state, bytes) when is_binary(bytes) do
    graphemes(bytes) |> reduce(state, &step/2)
  end

  def lines(%__MODULE__{buffer: buffer}) do
    to_lines(buffer)
  end

  defp step("\e", state) do
    %{state | pending: "\e"}
  end

  defp step(ch, %{pending: nil} = state) do
    input(ch, state)
  end

  defp step(ch, state) do
    seq = state.pending <> ch
    proceed(seq, state)
  end

  defp proceed(seq, state) do
    act(seq, state, done?(seq))
  end

  defp act(seq, state, true) do
    parse(seq, %{state | pending: nil})
  end

  defp act(seq, state, false) do
    %{state | pending: seq}
  end

  defp input("\r", s), do: %{s | cursor: {0, elem(s.cursor, 1)}}
  defp input("\n", s), do: newline(s)
  defp input("\t", s), do: %{s | cursor: {tab(elem(s.cursor, 0)), elem(s.cursor, 1)}}
  defp input("\b", s), do: %{s | cursor: {back(elem(s.cursor, 0)), elem(s.cursor, 1)}}
  defp input(ch, s), do: cell(ch, s)

  defp parse(<<_::binary>> = seq, s) when seq in ["\e7", "\e8", "\e(", "\e)"], do: s
  defp parse("\e[" <> r, s), do: handle(r, s)
  defp parse("\e]" <> _, s), do: s
  defp parse(_, s), do: s

  defp cell(ch, %{cursor: {x, y}, buffer: b, width: w} = s) do
    c = new(ch)
    nb = put(b, x, y, c)
    place(nb, s, x, y, w)
  end

  defp place(nb, s, x, _y, w) when x + 1 >= w do
    newline(%{s | buffer: nb})
  end

  defp place(nb, s, x, y, _w) do
    %{s | buffer: nb, cursor: {x + 1, y}}
  end

  defp newline(%{cursor: {_, y}, height: h} = s) when y + 1 >= h do
    %{s | cursor: {0, h - 1}}
  end

  defp newline(%{cursor: {_, y}} = s) do
    %{s | cursor: {0, y + 1}}
  end

  defp tab(x) do
    min((((x + 8) / 8) |> trunc) * 8, 79)
  end

  defp back(x) do
    max(x - 1, 0)
  end
end
