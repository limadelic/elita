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

  def get_hit_count(cassette_key, idx) do
    key = {cassette_key, idx}
    get(__MODULE__, fn state -> Map.get(state, key, 0) end)
  end

  def increment_hit_count(cassette_key, idx) do
    key = {cassette_key, idx}
    get_and_update(__MODULE__, fn state ->
      new_count = Map.get(state, key, 0) + 1
      {new_count, Map.put(state, key, new_count)}
    end)
  end
end
