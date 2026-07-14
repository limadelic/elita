defmodule El.Puppet.Filter do
  import String, only: [replace: 3, trim: 1, split: 2, contains?: 2]
  import El.Log, only: [write: 1]
  import Enum, only: [find: 3, reverse: 1]
  import List, only: [last: 1]
  import El.Puppet.Polish, only: [polish: 1, final: 1, noclutter: 1]

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

  defp clean(text) do
    text
    |> replace(~r/\e\[[0-9]*[GfH]/, " ")
    |> replace(~r/\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/, "")
  end
end
