defmodule Elita.Parser do
  import String, only: [contains?: 2, split: 2, split: 3, trim: 1]
  import Enum, only: [drop: 2, map: 2, filter: 2, into: 2]

  def has_tools?(reply) do
    contains?(reply, "<function_calls>")
  end

  def extract(reply) do
    reply
    |> split("<invoke name=\"")
    |> drop(1)
    |> map(&parse/1)
    |> filter(& &1)
  end

  defp parse(block) do
    parse_name(split(block, "\">", parts: 2))
  end

  defp parse_name([name, rest]), do: {name, params(rest)}
  defp parse_name(_), do: nil

  defp params(params) do
    params
    |> split("<parameter name=\"")
    |> drop(1)
    |> map(&param/1)
    |> into(%{})
  end

  defp param(block) do
    param_name(split(block, "\">", parts: 2))
  end

  defp param_name([name, rest]), do: param_value(name, split(rest, "</parameter>"))
  defp param_name(_), do: {"", ""}

  defp param_value(name, [value | _]), do: {name, trim(value)}
  defp param_value(_, _), do: {"", ""}
end