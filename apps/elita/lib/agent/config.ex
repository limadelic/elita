defmodule Agent.Config do
  import Enum, only: [map: 2, reject: 2]
  import String, only: [to_atom: 1, split: 3, trim: 1]
  import Application, only: [get_env: 2]

  def load do
    get_env(:elita, :registrations)
    |> fetch()
  end

  defp fetch(nil), do: []
  defp fetch(value), do: parse(value)

  defp parse(value) do
    value
    |> split(",", [])
    |> map(&item/1)
    |> reject(&is_nil/1)
  end

  defp item(entry) do
    entry
    |> split(":", parts: 2)
    |> build()
  end

  defp build([name, folder]) do
    {to_atom(trim(name)), trim(folder)}
  end

  defp build(_), do: nil
end
