defmodule Agent.Config do
  def load do
    System.get_env("AGENT_REGISTRATIONS")
    |> load_entries()
  end

  defp load_entries(nil), do: []
  defp load_entries(value), do: parse(value)

  defp parse(value) do
    value
    |> String.split(",")
    |> Enum.map(&parse_entry/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_entry(entry) do
    entry
    |> String.split(":", parts: 2)
    |> to_config()
  end

  defp to_config([name, folder]) do
    {String.to_atom(String.trim(name)), String.trim(folder)}
  end

  defp to_config(_), do: nil
end
