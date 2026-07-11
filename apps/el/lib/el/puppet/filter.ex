defmodule El.Puppet.Filter do
  import String, only: [replace: 3, trim: 1, split: 2, contains?: 2]
  import Enum, only: [at: 3]

  def answer?(buffer, question) do
    buffer |> presence(question)
  end

  def mark(buffer) do
    if contains?(buffer, "⏺") do
      buffer
      |> split("\e[H")
      |> at(-1, "")
      |> clean()
      |> scan()
    else
      buffer |> polish() |> final()
    end
  end

  defp scan(text) do
    text
    |> split("⏺")
    |> at(1, text)
    |> trim()
    |> replace(~r/\r.*/, "")
    |> trim()
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
    |> replace(~r/\(esc to interrupt\)/i, "")
    |> replace(~r/·\s+\w+…/, "")
    |> replace(~r/Type \? for shortcuts[^\n]*/i, "")
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
    replace(text, ~r/\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/, "")
  end
end
