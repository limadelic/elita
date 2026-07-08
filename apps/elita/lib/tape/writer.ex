defmodule Tape.Writer do
  import Agent, only: [start_link: 2, get_and_update: 2]
  import Map, only: [get: 3, put: 3]

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
    get_and_update(__MODULE__, &check_claim(&1, key, times))
  end

  def claim_agent(cassette_key, agent, idx, times) do
    key = {cassette_key, agent, idx}
    get_and_update(__MODULE__, &check_claim(&1, key, times))
  end

  defp check_claim(state, key, "always") do
    count = get(state, key, 0)
    {true, put(state, key, count + 1)}
  end

  defp check_claim(state, key, times) do
    count = get(state, key, 0)
    claim_if_available(state, key, count, count < times)
  end

  defp claim_if_available(state, key, count, true) do
    {true, put(state, key, count + 1)}
  end

  defp claim_if_available(state, _key, _count, false) do
    {false, state}
  end
end
