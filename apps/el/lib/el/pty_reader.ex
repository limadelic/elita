defmodule El.PtyReader do
  def start(file, parent) do
    file.open("/dev/stdin", [:read, :binary, :raw])
    |> handle_open(file, parent)
  end

  defp handle_open({:ok, stdin}, file, parent), do: loop(file, stdin, parent)
  defp handle_open({:error, _}, _file, _parent), do: :ok

  defp loop(file, stdin, parent) do
    file.read(stdin, 1)
    |> handle_read(file, stdin, parent)
  end

  defp handle_read({:ok, data}, file, stdin, parent) do
    send(parent, {:stdin, data})
    loop(file, stdin, parent)
  end

  defp handle_read(_, file, stdin, _parent) do
    file.close(stdin)
  end
end
