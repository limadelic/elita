defmodule Mem do
  def create(name) do
    :ets.new(table(name), [:set, :public, :named_table])
  end

  def table(name) do
    :"mem_#{name}"
  end
end