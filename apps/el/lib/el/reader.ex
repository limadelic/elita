defmodule El.Reader do
  @moduledoc false
  import El.Trace

  def start(file, parent) do
    open?(file, parent)
  end

  defp open?(file, parent) do
    file.open("/dev/tty", [:read, :binary, :raw])
    |> init(file, parent)
  end

  defp init({:ok, stdin}, file, parent), do: loop(file, stdin, parent)
  defp init({:error, _}, file, parent), do: scan(file, parent)

  defp scan(file, parent) do
    file.read(:user, 1024) |> input(file, parent)
  end

  defp input({:ok, data}, file, parent) do
    send(parent, {:stdin, data})
    scan(file, parent)
  end

  defp input(:eof, _file, _parent) do
    emit("stdin_eof")
    :ok
  end

  defp input({:error, reason}, _file, _parent) do
    emit("stdin_error", inspect(reason))
    :ok
  end

  defp loop(file, stdin, parent) do
    file.read(stdin, 1)
    |> data(file, stdin, parent)
  end

  defp data({:ok, data}, file, stdin, parent) do
    send(parent, {:stdin, data})
    loop(file, stdin, parent)
  end

  defp data({:error, reason}, file, stdin, _parent) do
    emit("stdin_error", inspect(reason))
    file.close(stdin)
  end

  defp data(:eof, file, stdin, _parent) do
    emit("stdin_eof")
    file.close(stdin)
  end
end
