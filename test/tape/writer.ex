defmodule Tape.Writer do
  import Agent

  def start_link(_) do
    start_link(fn -> :lock end, name: __MODULE__)
  end

  def acquire(fun) do
    get_and_update(__MODULE__, fn :lock ->
      {fun.(), :lock}
    end)
  end
end
