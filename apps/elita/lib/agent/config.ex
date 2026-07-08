defmodule Agent.Config do
  import Enum, only: [map: 2, reject: 2]
  import String, only: [to_atom: 1, split: 3, trim: 1]
  import System, only: [get_env: 1]

  def load do
    get_env("AGENT_REGISTRATIONS")
    |> load_entries()
  end

  defp load_entries(nil), do: []
  defp load_entries(value), do: parse(value)

  defp parse(value) do
    value
    |> split(",", [])
    |> map(&parse_entry/1)
    |> reject(&is_nil/1)
  end

  defp parse_entry(entry) do
    entry
    |> split(":", parts: 2)
    |> to_config()
  end

  defp to_config([name, folder]) do
    {to_atom(trim(name)), trim(folder)}
  end

  defp to_config(_), do: nil
end
