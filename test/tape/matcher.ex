defmodule Tape.Matcher do
  def contains(a, b) when is_map(a) and is_map(b),
    do: Enum.all?(a, fn {k, v} -> contains(v, b[k] || b[to_string(k)]) end)

  def contains(a, b) when is_list(a) and is_list(b),
    do: Enum.all?(a, fn x -> Enum.any?(b, &contains(x, &1)) end)

  def contains(<<"/" <> rest::binary>>, b) when is_binary(b) do
    if String.ends_with?(rest, "/"), do: regex_match(rest, b), else: String.contains?(b, "/" <> rest)
  end

  def contains(a, b) when is_binary(a) and is_binary(b), do: String.contains?(b, a)

  def contains(a, b), do: a == b

  defp regex_match(rest, b) do
    pattern = String.slice(rest, 0, String.length(rest) - 1)
    Regex.match?(Regex.compile!(pattern), b)
  end
end
