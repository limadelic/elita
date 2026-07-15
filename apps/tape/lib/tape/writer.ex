defmodule Tape.Writer do
  import Agent, only: [start_link: 2, get_and_update: 2, get: 2]
  import Map, only: [get: 3, put: 3]

  def start_link(tape) do
    start_link(fn -> %{cassette: tape} end, name: __MODULE__)
  end

  def cassette do
    get(__MODULE__, fn state -> Map.get(state, :cassette) end)
  end

  def acquire(fun) do
    get_and_update(__MODULE__, fn state ->
      {fun.(), state}
    end)
  end

  def claim(cassette, idx, times) do
    key = {cassette, idx}
    get_and_update(__MODULE__, &allow(&1, key, times))
  end

  def bind(cassette, agent, idx, times) do
    key = {cassette, agent, idx}
    get_and_update(__MODULE__, &allow(&1, key, times))
  end

  defp allow(state, key, "always") do
    count = get(state, key, 0)
    {true, put(state, key, count + 1)}
  end

  defp allow(state, key, times) do
    count = get(state, key, 0)
    admit(state, key, count, count < times)
  end

  defp admit(state, key, count, true) do
    {true, put(state, key, count + 1)}
  end

  defp admit(state, _key, _count, false) do
    {false, state}
  end
end
