defmodule Mem do
  def setup do
    ensure(depth())
  end

  def create(name) do
    name |> table() |> init()
  end

  defp init(table) do
    table |> :ets.whereis() |> fresh(table)
  end

  defp fresh(:undefined, table) do
    :ets.new(table, [:set, :public, :named_table])
  end

  defp fresh(_exists, table) do
    :ets.delete_all_objects(table)
  end

  defp ensure(table) do
    table |> :ets.whereis() |> found(table)
  end

  defp found(:undefined, table) do
    :ets.new(table, [:set, :public, :named_table])
  end

  defp found(_exists, _table) do
    :ok
  end

  def table(name) do
    :"mem_#{name}"
  end

  def depth do
    :mem_depth_global
  end
end
