defmodule El.Puppet.Filter do
  import String, only: [replace: 3, trim: 1, split: 2, contains?: 2]
  import El.Log, only: [write: 1]
  import Enum, only: [find: 3, reverse: 1]
  import List, only: [last: 1]

  def answer?(buffer, question) do
    buffer |> presence(question)
  end

  def mark(buffer) do
    dispatch(buffer, contains?(buffer, "⏺"))
  end

  defp dispatch(buffer, true) do
    buffer |> split("\e[H") |> frame() |> body()
  end

  defp dispatch(buffer, false) do
    buffer |> polish() |> final()
  end

  defp frame(frames) do
    find(reverse(frames), "", &contains?(&1, "⏺"))
  end

  defp body(text) do
    pull(text) |> trim() |> strip() |> trim()
  end

  defp pull(text) do
    result = extract(text)
    write("extract: #{inspect(result)}\n")
    result
  end

  defp extract(text) do
    text |> clean() |> split("⏺") |> last() |> fallback(text)
  end

  defp fallback(nil, text), do: text
  defp fallback(x, _text), do: x

  defp strip(text) do
    text |> replace(~r/[✻❯].*/, "") |> replace(~r/\(esc.*/, "") |> replace(~r/\r.*/, "")
  end

  defp presence(buffer, question) when byte_size(buffer) > 0 do
    question |> removed?(buffer)
  end

  defp presence(_buffer, _question), do: false

  defp removed?(q, b) do
    b |> polish() |> noclutter() |> replace(q, "") |> trim() |> full?()
  end

  defp full?(buffer), do: byte_size(buffer) > 0

  def polish(buffer) do
    buffer |> safe() |> clean()
  end

  defp safe(buffer) do
    buffer |> validate() |> native()
  end

  defp validate(buffer) do
    :unicode.characters_to_binary(buffer, :utf8, :utf8)
  end

  defp native(r) when is_binary(r), do: r
  defp native({:incomplete, v, _}), do: v
  defp native({:error, v, _}), do: v

  def final(stripped) do
    stripped |> noclutter() |> trim() |> pick(stripped)
  end

  defp pick(cleaned, _stripped) when byte_size(cleaned) > 20, do: cleaned
  defp pick(_cleaned, stripped), do: stripped

  defp noclutter(text) do
    text |> prompts() |> boxes() |> spaces()
  end

  defp prompts(text) do
    text
    |> mute()
    |> mask()
  end

  defp mute(text) do
    text
    |> replace(~r/\(esc to interrupt\)/i, "")
    |> replace(~r/·\s+\w+…/, "")
    |> replace(~r/Type \? for shortcuts[^\n]*/i, "")
  end

  defp mask(text) do
    text
    |> replace(~r/Press [Ctrl\+C]+ to exit[^\n]*/i, "")
    |> replace(~r/\(type .+ for help\)[^\n]*/i, "")
  end

  defp boxes(text) do
    replace(text, ~r/[┌┐└┘─│├┤┬┴┼]/, "")
  end

  defp spaces(text) do
    replace(text, ~r/\s+/, " ")
  end

  defp clean(text) do
    text
    |> replace(~r/\e\[[0-9]*[GfH]/, " ")
    |> replace(~r/\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/, "")
  end
end
