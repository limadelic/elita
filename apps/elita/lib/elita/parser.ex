defmodule Elita.Parser do
  import String, only: [contains?: 2, split: 2, split: 3, trim: 1]
  import Enum, only: [drop: 2, map: 2, filter: 2, into: 2]

  def has_tools?(reply), do: contains?(reply, "<function_calls>")

  def extract(reply) do
    reply
    |> split("<invoke name=\"")
    |> drop(1)
    |> map(&parse/1)
    |> filter(& &1)
  end

  defp parse(block), do: name(split(block, "\">", parts: 2))

  defp name([name, rest]), do: {name, params(rest)}
  defp name(_), do: nil

  defp params(params) do
    params
    |> split("<parameter name=\"")
    |> drop(1)
    |> map(&param/1)
    |> into(%{})
  end

  defp param(block), do: kv(split(block, "\">", parts: 2))

  defp kv([name, rest]), do: value(name, split(rest, "</parameter>"))
  defp kv(_), do: {"", ""}

  defp value(name, [value | _]), do: {name, trim(value)}
  defp value(_, _), do: {"", ""}
end