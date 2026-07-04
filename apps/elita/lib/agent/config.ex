defmodule Agent.Config do
  def load do
    case System.get_env("AGENT_REGISTRATIONS") do
      nil -> []
      value -> parse(value)
    end
  end

  defp parse(value) do
    value
    |> String.split(",")
    |> Enum.map(&parse_entry/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_entry(entry) do
    case String.split(entry, ":", parts: 2) do
      [name, folder] -> {String.to_atom(String.trim(name)), String.trim(folder)}
      _ -> nil
    end
  end
end
