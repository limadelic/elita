defmodule El.PtyReader do
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
    case file.read(:user, 1024) do
      {:ok, data} ->
        log_hex(data)
        send(parent, {:stdin, data})
        loop_user(file, parent)
      :eof ->
        :ok
      {:error, _} ->
        :ok
    end
  end

  defp loop(file, stdin, parent) do
    file.read(stdin, 1024)
    |> handle_read(file, stdin, parent)
  end

  defp handle_read({:ok, data}, file, stdin, parent) do
    log_hex(data)
    send(parent, {:stdin, data})
    loop(file, stdin, parent)
  end

  defp handle_read(_, file, stdin, _parent) do
    file.close(stdin)
  end

  defp log_hex(_data) do
    :ok
  end
end
