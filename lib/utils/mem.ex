defmodule Mem do
  def create do
    :ets.new(table(), [:set, :public, :named_table])
  end

  def table do
    :"mem_#{:erlang.pid_to_list(self())}"
  end
end