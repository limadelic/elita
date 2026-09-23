defmodule Freeq.Tag do
  import String, only: [split: 2, split: 3]
  import Enum, only: [find_value: 2]

  def read("@" <> rest, name) do
    blob = rest |> split(" ", parts: 2) |> hd()
    find_tag(blob, name)
  end

  def read(_line, _name), do: nil

  defp find_tag(blob, name) do
    blob
    |> split(";")
    |> find_value(&match_tag(&1, name))
  end

  defp match_tag(tag, name) do
    case split(tag, "=", parts: 2) do
      [^name] -> ""
      [^name, value] -> value
      _ -> nil
    end
  end
end
