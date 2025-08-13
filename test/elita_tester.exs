defmodule ElitaTester do
  import ExUnit.Assertions
  import Elita, only: [start_link: 2, cast: 2, call: 2]

  def start(name) do
    setup()
    start_link(normalize_mixins([name]), name)
  end

  def start(name, mixins) do
    setup()
    start_link(normalize_mixins(mixins), name)
  end

  defp normalize_mixins(mixins) when is_list(mixins), do: mixins
  defp normalize_mixins(mixin), do: [mixin]

  def stop(name) do
    GenServer.stop(via(name))
  rescue
    _ -> :ok
  end

  defp via(name) do
    {:via, Registry, {ElitaRegistry, name}}
  end

  defp setup do
    :ok
  end

  def tell(name, msg) do
    IO.puts("Tell: #{msg}")
    cast(name, msg)
  end

  def ask(name, q) do
    IO.puts("Q: #{q}")
    answer = call(name, q)
    IO.puts("A: #{answer}")
    answer
  end

  def verify(name, a, q) do
    answer = ask(name, q)
    assert String.contains?(String.downcase(answer), String.downcase("#{a}")),
           "Expected '#{answer}' to contain '#{a}'"
  end

  def wait_until(agent, cond) do
    verify(agent, "yes", "did you #{cond}?")
  rescue
    _ -> wait_until(agent, cond)
  end
end
