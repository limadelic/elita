defmodule El.Puppet.Parse do
  import String, only: [split: 3, to_atom: 1]

  def envelope(text) do
    text |> split("\n", parts: 2) |> extract()
  end

  defp extract(["[ask " <> rest, message]), do: unpack(:ask, rest, message)
  defp extract(["[reply " <> rest, message]), do: unpack(:reply, rest, message)
  defp extract(["[from " <> rest, message]), do: unpack(:tell, rest, message)
  defp extract(_), do: :none

  defp unpack(kind, rest, message) do
    rest |> split("]", parts: 2) |> validate(kind, message)
  end

  defp validate([sender, ""], kind, message), do: {kind, to_atom(sender), message}
  defp validate(_, _kind, _message), do: :none
end
