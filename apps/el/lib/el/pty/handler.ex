defmodule El.Pty.Handler do
  @moduledoc false
  import El.Pty.Dsr
  import El.Pty.Size

  def write(_port, _pty, :drop), do: :ok
  def write(port, pty, transformed) do
    import El.Log, only: [write: 1]
    size = if is_binary(transformed), do: byte_size(transformed), else: "?"
    write("handler: writing to pty, size=#{size}\n")
    port.command(pty, transformed)
  rescue
    e ->
      import El.Log, only: [write: 1]
      write("handler: write error: #{inspect(e)}\n")
      raise e
  end

  def respond(port, pty, data, _state) do
    {rows, cols} = default()
    send(port, pty, scan(data, rows, cols, ""))
  end

  defp send(port, pty, {response, _}) when response != "" do
    port.command(pty, response)
  end

  defp send(_, _, _), do: :ok
end
