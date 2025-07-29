defmodule CLI do

  def main([name]) do
    Node.start(:"#{name}@127.0.0.1")
    {:ok, pid} = Elita.start_link(String.to_atom(name))
    chat(pid)
  end

  defp chat(pid) do
    input = IO.gets("> ") |> String.trim()
    resp = Elita.act(pid, input)
    IO.puts(resp)
    chat(pid)
  end
end