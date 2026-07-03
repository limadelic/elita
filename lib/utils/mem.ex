defmodule Mem do
  def init_global do
    create_depth_table(:ets.whereis(depth_table()))
  end

  defp create_depth_table(:undefined) do
    :ets.new(depth_table(), [:set, :public, :named_table])
  end

  defp create_depth_table(_), do: :ok

  def create do
    :ets.new(table(), [:set, :public, :named_table])
  end

  def table do
    :"mem_#{:erlang.pid_to_list(self())}"
  end

  def depth_table do
    :mem_depth_global
  end
end