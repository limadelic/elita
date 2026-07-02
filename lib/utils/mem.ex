defmodule Mem do
  def init_global do
    case :ets.whereis(depth_table()) do
      :undefined -> :ets.new(depth_table(), [:set, :public, :named_table])
      _ -> :ok
    end
  end

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