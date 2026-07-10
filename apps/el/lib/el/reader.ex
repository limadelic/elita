defmodule El.Reader do
  @moduledoc false
  import El.Trace
  import El.Log, only: [write: 1]

  def start(_file, parent) do
    write("reader: start called with parent=#{inspect(parent)}\n")
    write("reader: starting, pumping stdin to PTY\n")
    pump(parent)
  end

  defp pump(parent) do
    write("reader: about to read line from stdin\n")
    case :io.get_line(~c'') do
      {:error, reason} ->
        write("reader: io.get_line error: #{inspect(reason)}\n")
        emit("stdin_error", inspect(reason))
        :ok
      :eof ->
        write("reader: io.get_line EOF\n")
        emit("stdin_eof")
        :ok
      data ->
        write("reader: got line, size=#{byte_size(data)}\n")
        write("reader: parent PID=#{inspect(parent)}, sending {:stdin, data}\n")
        result = send(parent, {:stdin, data})
        write("reader: send returned #{inspect(result)}\n")
        pump(parent)
    end
  end
end
