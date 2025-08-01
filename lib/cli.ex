defmodule CLI do

  def main([name]) do
    Node.start(:"#{name}@127.0.0.1")
    {:ok, pid} = Elita.start_link(String.to_atom(name))
    chat(pid)
  end

  defp chat(pid) do
    IO.gets("> ")
    |> String.trim()
    |> Elita.act(pid)
    |> IO.puts()
    
    chat(pid)
  end
end