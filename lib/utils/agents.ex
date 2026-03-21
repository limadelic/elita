defmodule Agents do
  @moduledoc false

  def exists?(name) when is_binary(name) do
    case Registry.lookup(ElitaRegistry, String.downcase(name)) do
      [] -> false
      _ -> true
    end
  end

  def missing(name), do: "Error: agent '#{name}' is not running — spawn it first"
end
