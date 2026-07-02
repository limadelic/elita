defmodule Tape.Writer do
  import Agent

  def start_link(_) do
    start_link(fn -> %{} end, name: __MODULE__)
  end

  def acquire(fun) do
    get_and_update(__MODULE__, fn state ->
      {fun.(), state}
    end)
  end

  def claim(cassette_key, idx, times) do
    key = {cassette_key, idx}
    get_and_update(__MODULE__, fn state ->
      current_count = Map.get(state, key, 0)
      if times == "always" || current_count < times do
        {true, Map.put(state, key, current_count + 1)}
      else
        {false, state}
      end
    end)
  end
end
