defmodule ElitaTester do
  import ExUnit.Assertions
  import Elita, only: [start_link: 2, cast: 2, call: 2]

  def spawn(name) do
    setup()
    start_link(Atom.to_string(name), list([Atom.to_string(name)]))
  end

  def spawn(name, configs) do
    setup()
    start_link(Atom.to_string(name), list(configs) |> Enum.map(&Atom.to_string/1))
  end

  defp list(configs) when is_list(configs), do: configs
  defp list(config), do: [config]

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
    cast(Atom.to_string(name), msg)
  end

  def ask(name, q) do
    IO.puts("Q: #{q}")
    answer = call(Atom.to_string(name), q)
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
