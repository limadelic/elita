defmodule El.Puppet.Polish do
  import String, only: [replace: 3, trim: 1]

  def polish(buffer) do
    buffer |> safe() |> clean()
  end

  def final(stripped) do
    stripped |> noclutter() |> trim() |> pick(stripped)
  end

  def noclutter(text) do
    text |> prompts() |> boxes() |> spaces()
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

  defp pick(cleaned, _stripped) when byte_size(cleaned) > 20, do: cleaned
  defp pick(_cleaned, stripped), do: stripped

  defp prompts(text) do
    text |> mute() |> mask()
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
