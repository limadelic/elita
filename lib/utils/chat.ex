defmodule Chat do

  def main([name]) do
    Node.start(:"#{name}@127.0.0.1")
    {:ok, pid} = Elita.start_link(String.to_atom(name))
    repl(name, pid)
  end

  defp repl(name, pid) do
    IO.gets("#{name} > ")
    |> repl(name, pid)
  end

  defp repl(:eof, _name, _pid) do
    IO.puts("Bye!")
  end

  defp repl(input, name, pid) when is_binary(input) do
    input
    |> String.trim()
    |> Elita.act(pid)
    |> IO.puts()
    
    repl(name, pid)
  end
end