defmodule Agent.Registry do
  def create do
    :ets.new(table(), [:set, :public, :named_table])
  end

  def register(name, folder, pid) do
    :ets.insert(table(), {name, pid, folder})
    :ok
  end

  def lookup(name) do
    case :ets.lookup(table(), name) do
      [{^name, pid, folder}] -> {:ok, {pid, folder}}
      [] -> {:error, :not_found}
    end
  end

  def remove(name) do
    :ets.delete(table(), name)
    :ok
  end

  defp table do
    :agent_registry
  end
end
