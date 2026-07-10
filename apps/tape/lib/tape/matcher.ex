defmodule Tape.Matcher do
  import Enum, only: [all?: 2, any?: 2]
  import String, only: [contains?: 2, ends_with?: 2, slice: 3]
  import Map, only: [fetch: 2]
  import Regex, only: [compile!: 1]

  def contains(a, b) do
    route(a, b)
  end

  defp route(a, b) when is_map(a) do
    map(a, b, is_map(b))
  end

  defp route(a, b) when is_list(a) do
    list(a, b, is_list(b))
  end

  defp route(<<"/" <> _::binary>> = a, b) do
    regex(a, b)
  end

  defp route(a, b) do
    eq(a, b)
  end

  defp map(a, b, true) do
    all?(a, &entry(&1, b))
  end

  defp map(_a, _b, false) do
    false
  end

  defp list(a, b, true) do
    all?(a, &item(&1, b))
  end

  defp list(_a, _b, false) do
    false
  end

  defp regex(<<"/" <> rest::binary>>, b) do
    type(rest, b, is_binary(b))
  end

  defp type(rest, b, true) do
    test(rest, b)
  end

  defp type(_rest, _b, false) do
    false
  end

  defp eq(a, b) do
    binary(a, b, is_binary(a), is_binary(b))
  end

  defp binary(a, b, true, true) do
    contains?(b, a)
  end

  defp binary(a, b, false, false) do
    a == b
  end

  defp binary(_a, _b, _ab, _bb) do
    false
  end

  defp entry({k, v}, b) do
    val = value(b, k)
    contains(v, val)
  end

  defp value(b, k) do
    get(fetch(b, k), b, k)
  end

  defp get({:ok, val}, _b, _k), do: val
  defp get(:error, b, k), do: b[to_string(k)]

  defp item(x, b) do
    any?(b, &contains(x, &1))
  end

  defp test(rest, b) do
    done(rest, b, ends_with?(rest, "/"))
  end

  defp done(rest, b, true), do: match(rest, b)
  defp done(rest, b, false), do: contains?(b, "/" <> rest)

  defp match(rest, b) do
    pattern = slice(rest, 0, byte_size(rest) - 1)
    b =~ compile!(pattern)
  end
end
