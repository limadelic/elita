defmodule Agent.Registry do
  def create do
    :ets.new(table(), [:set, :public, :named_table])
  end

  def register(name, folder, pid) do
    :ets.insert(table(), {name, pid, folder})
    :ok
  end

  def lookup(name) do
    :ets.lookup(table(), name)
    |> match_lookup(name)
  end

  defp match_lookup([{name, pid, folder}], name), do: {:ok, {pid, folder}}
  defp match_lookup([], _name), do: {:error, :not_found}

  def remove(name) do
    :ets.delete(table(), name)
    :ok
  end

  defp table do
    :agent_registry
  end
end
