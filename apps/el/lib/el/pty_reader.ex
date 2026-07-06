defmodule El.PtyReader do
  def start(file, parent) do
    case file.read(:user, 0) do
      {:ok, _} -> loop_user(file, parent)
      :eof -> :ok
      {:error, _} -> try_tty(file, parent)
    end
  end

  defp try_tty(file, parent) do
    file.open("/dev/tty", [:read, :binary, :raw])
    |> handle_open(file, parent)
  end

  defp handle_open({:ok, stdin}, file, parent), do: loop(file, stdin, parent)
  defp handle_open({:error, _}, _file, _parent), do: :ok

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

  defp log_hex(data) do
    log_path()
    |> File.open([:append])
    |> write_log(hex_line(data))
  end

  defp hex_line(data) do
    hex = Base.encode16(data, case: :lower)
    timestamp = System.os_time(:millisecond)
    "#{timestamp} #{hex} (#{data})\n"
  end

  defp log_path do
    "/private/tmp/claude-501/-Users-mike-dev-self-elita/2afd908c-b2e0-44ec-857d-7d91bd975077/scratchpad/ptyreader.hex"
  end

  defp write_log({:ok, file}, line) do
    IO.write(file, line)
    File.close(file)
  end

  defp write_log(_, _), do: nil
end
