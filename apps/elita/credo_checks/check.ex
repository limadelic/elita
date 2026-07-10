defmodule Elita.Credo.Check do
  import Enum, only: [any?: 2]
  import String, only: [upcase: 1, ends_with?: 2]

  def builtin?(":" <> _), do: true
  def builtin?("Elixir.Kernel" <> _), do: true
  def builtin?("Elixir.Access" <> _), do: true
  def builtin?(_), do: false

  def listed?(name, allowlist) do
    any?(allowlist, &allow?(name, to_string(&1)))
  end

  def allow?(name, name), do: true

  def allow?(name, s) do
    suffix?(ends_with?(name, "." <> s), name, s)
  end

  defp suffix?(true, _name, _s), do: true
  defp suffix?(false, name, s), do: ends_with?(name, s)

  def special?(":" <> _), do: true

  def special?(module) when module in [:Kernel, :Access], do: true

  def special?(module) do
    s = to_string(module)
    s in ["Kernel", "Access", "Elixir.Kernel", "Elixir.Access"]
  end

  def compound?(atom) when is_atom(atom), do: atom |> to_string() |> word?()
  def compound?(s), do: s |> word?()

  def word?(s) when not is_binary(s), do: false
  def word?(s) when byte_size(s) == 0, do: false
  def word?(s), do: s |> matched() |> cased(s)

  def matched(s), do: s =~ ~r/^[A-Z][a-z]+[A-Z]/

  def cased(true, s), do: upcase(s) != s
  def cased(false, _), do: false
end
