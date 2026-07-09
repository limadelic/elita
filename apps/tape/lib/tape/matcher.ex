defmodule Tape.Matcher do
  import Enum, only: [all?: 2, any?: 2]
  import String, only: [contains?: 2, ends_with?: 2, slice: 3]
  import Map, only: [fetch: 2]
  import Regex, only: [compile!: 1]

  def contains(a, b) do
    dispatch_contains(a, b)
  end

  defp dispatch_contains(a, b) when is_map(a) do
    dispatch_map_contains(a, b, is_map(b))
  end

  defp dispatch_contains(a, b) when is_list(a) do
    dispatch_list_contains(a, b, is_list(b))
  end

  defp dispatch_contains(<<"/" <> _::binary>> = a, b) do
    dispatch_regex_contains(a, b)
  end

  defp dispatch_contains(a, b) do
    equal_or_contains(a, b)
  end

  defp dispatch_map_contains(a, b, true) do
    all?(a, &check_map_entry(&1, b))
  end

  defp dispatch_map_contains(_a, _b, false) do
    false
  end

  defp dispatch_list_contains(a, b, true) do
    all?(a, &check_list_item(&1, b))
  end

  defp dispatch_list_contains(_a, _b, false) do
    false
  end

  defp dispatch_regex_contains(<<"/" <> rest::binary>>, b) do
    dispatch_by_binary_type(rest, b, is_binary(b))
  end

  defp dispatch_by_binary_type(rest, b, true) do
    check_regex_or_string(rest, b)
  end

  defp dispatch_by_binary_type(_rest, _b, false) do
    false
  end

  defp equal_or_contains(a, b) do
    check_binary_contains(a, b, is_binary(a), is_binary(b))
  end

  defp check_binary_contains(a, b, true, true) do
    contains?(b, a)
  end

  defp check_binary_contains(a, b, false, false) do
    a == b
  end

  defp check_binary_contains(_a, _b, _ab, _bb) do
    false
  end

  defp check_map_entry({k, v}, b) do
    val = get_map_value(b, k)
    contains(v, val)
  end

  defp get_map_value(b, k) do
    get_by_atom_or_string(fetch(b, k), b, k)
  end

  defp get_by_atom_or_string({:ok, val}, _b, _k), do: val
  defp get_by_atom_or_string(:error, b, k), do: b[to_string(k)]

  defp check_list_item(x, b) do
    any?(b, &contains(x, &1))
  end

  defp check_regex_or_string(rest, b) do
    check_regex_match(rest, b, ends_with?(rest, "/"))
  end

  defp check_regex_match(rest, b, true), do: regex_match(rest, b)
  defp check_regex_match(rest, b, false), do: contains?(b, "/" <> rest)

  defp regex_match(rest, b) do
    pattern = slice(rest, 0, byte_size(rest) - 1)
    b =~ compile!(pattern)
  end
end
