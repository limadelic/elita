defmodule El.PtyReader do
  @moduledoc false
  import El.Trace

  def start(file, parent) do
    try_tty(file, parent)
  end

  defp try_tty(file, parent) do
    file.open("/dev/tty", [:read, :binary, :raw])
    |> handle_open(file, parent)
  end

  defp handle_open({:ok, stdin}, file, parent), do: loop(file, stdin, parent)
  defp handle_open({:error, _}, file, parent), do: loop_user(file, parent)

  defp loop_user(file, parent) do
    file.read(:user, 1024) |> handle_user_read(file, parent)
  end

  defp handle_user_read({:ok, data}, file, parent) do
    send(parent, {:stdin, data})
    loop_user(file, parent)
  end

  defp handle_user_read(:eof, _file, _parent) do
    log_event("stdin_eof")
    :ok
  end

  defp handle_user_read({:error, reason}, _file, _parent) do
    log_event("stdin_error", inspect(reason))
    :ok
  end

  defp loop(file, stdin, parent) do
    file.read(stdin, 1)
    |> handle_read(file, stdin, parent)
  end

  defp handle_read({:ok, data}, file, stdin, parent) do
    send(parent, {:stdin, data})
    loop(file, stdin, parent)
  end

  defp handle_read({:error, reason}, file, stdin, _parent) do
    log_event("stdin_error", inspect(reason))
    file.close(stdin)
  end

  defp handle_read(:eof, file, stdin, _parent) do
    log_event("stdin_eof")
    file.close(stdin)
  end
end
