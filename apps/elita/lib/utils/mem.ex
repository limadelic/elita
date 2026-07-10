defmodule Mem do
  def setup do
    build(:ets.whereis(depth()))
  end

  defp build(:undefined) do
    :ets.new(depth(), [:set, :public, :named_table])
  end

  defp build(_), do: :ok

  def create do
    :ets.new(table(), [:set, :public, :named_table])
  end

  def table do
    :"mem_#{:erlang.pid_to_list(self())}"
  end

  def depth do
    :mem_depth_global
  end
end
