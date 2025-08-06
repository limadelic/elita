defmodule Chat do
  import String, only: [trim: 1, to_atom: 1]
  import IO, only: [gets: 1, puts: 1]
  import Elita, only: [start_link: 2, call: 2]
  import Node, only: [start: 1]

  def main([name]) do
    chat(to_atom(name), to_atom(name))
  end

  def main([agent, name]) do
    chat(to_atom(agent), to_atom(name))
  end

  defp chat(agent, name) do
    start(:"#{name}@127.0.0.1")
    {:ok, _pid} = start_link(agent, name)
    repl(name)
  end

  defp repl(agent) do
    case gets("#{agent} > ") do
      :eof -> puts("Bye!")
      input -> 
        puts call(agent, trim(input))
        repl(agent)
    end
  end
end