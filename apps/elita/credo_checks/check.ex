defmodule Elita.Credo.Check do
  def builtin?(":" <> _), do: true
  def builtin?("Elixir.Kernel" <> _), do: true
  def builtin?("Elixir.Access" <> _), do: true
  def builtin?(_), do: false

  def listed?(name, allowlist) do
    Enum.any?(allowlist, &match_allowed?(name, to_string(&1)))
  end

  def match_allowed?(name, name), do: true
  def match_allowed?(name, s) do
    check_suffix(String.ends_with?(name, "." <> s), name, s)
  end

  defp check_suffix(true, _name, _s), do: true
  defp check_suffix(false, name, s), do: String.ends_with?(name, s)

  def special?(":" <> _), do: true
  def special?(module) when module in [:Kernel, :Access], do: true
  def special?(module) do
    s = to_string(module)
    s in ["Kernel", "Access", "Elixir.Kernel", "Elixir.Access"]
  end
end
