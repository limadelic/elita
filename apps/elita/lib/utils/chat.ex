defmodule Chat do
  import Elita, only: [spawn: 2, request: 2]
  import IO, only: [gets: 1, puts: 1]
  import Node, only: [start: 1]
  import String, only: [trim: 1, to_atom: 1]

  def main([name]) do
    chat(to_atom(name), to_atom(name))
  end

  def main([agent, name]) do
    chat(to_atom(agent), to_atom(name))
  end

  defp chat(agent, name) do
    start(:"#{name}@127.0.0.1")
    {:ok, _pid} = spawn(agent, name)
    repl(name)
  end

  defp repl(agent) do
    gets("#{agent} > ") |> feed(agent)
  end

  defp feed(:eof, _agent) do
    puts("Bye!")
  end

  defp feed(input, agent) do
    puts(request(agent, trim(input)))
    repl(agent)
  end
end
