defmodule ElitaTester do
  import ExUnit.Assertions
  import Node, only: [set_cookie: 1]
  import Elita, only: [start_link: 2, cast: 2, call: 2]

  def start(name) do
    setup()
    start_link(name, name)
  end

  def start(agent, name) do
    setup()
    start_link(agent, name)
  end

  def stop(name) do
    GenServer.stop(via(name))
  rescue
    _ -> :ok
  end

  defp via(name) do
    {:via, Registry, {ElitaRegistry, name}}
  end

  defp setup do
    case Node.start(:"test@127.0.0.1") do
      {:ok, _} -> set_cookie(:elita)
      {:error, {:already_started, _}} -> set_cookie(:elita)
      {:error, _} -> :ok
    end
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
