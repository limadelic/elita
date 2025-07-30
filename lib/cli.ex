defmodule CLI do

  def main([name]) do
    Node.start(:"#{name}@127.0.0.1")
    {:ok, pid} = Elita.start_link(String.to_atom(name))
    chat(name, pid)
  end

  defp chat(name, pid) do
    IO.gets("#{name} > ")
    |> chat(name, pid)
  end

  defp chat(:eof, _name, _pid) do
    IO.puts("Bye!")
  end

  defp chat(input, name, pid) when is_binary(input) do
    input
    |> String.trim()
    |> Elita.act(pid)
    |> IO.puts()
    
    chat(name, pid)
  end
end