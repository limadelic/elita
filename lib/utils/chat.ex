defmodule Chat do
  import String, only: [trim: 1, to_atom: 1]
  import IO, only: [gets: 1, puts: 1]
  import Elita, only: [start_link: 1, chat: 2]
  import Node, only: [start: 1]

  def main([name]) do
    start(:"#{name}@127.0.0.1")
    {:ok, pid} = start_link(to_atom(name))
    repl(name, pid)
  end

  defp repl(name, pid) do
    gets("#{name} > ")
    |> repl(name, pid)
  end

  defp repl(:eof, _name, _pid) do
    puts("Bye!")
  end

  defp repl(input, name, pid) when is_binary(input) do
    input
    |> trim()
    |> chat(pid)
    |> puts()
    
    repl(name, pid)
  end
end