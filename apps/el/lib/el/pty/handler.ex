defmodule El.Pty.Handler do
  @moduledoc false
  import El.Pty.Dsr
  import El.Pty.Size

  def write(_port, _pty, :drop), do: :ok
  def write(port, pty, transformed), do: port.command(pty, transformed)

  def respond(port, pty, data, _state) do
    {rows, cols} = default()
    send(port, pty, scan(data, rows, cols, ""))
  end

  defp send(port, pty, {response, _}) when response != "" do
    port.command(pty, response)
  end

  defp send(_, _, _), do: :ok
end
