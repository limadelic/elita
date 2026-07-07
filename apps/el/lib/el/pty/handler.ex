defmodule El.Pty.Handler do
  @moduledoc false
  alias El.Pty.Dsr
  alias El.Pty.Size

  def process_input(_port, _pty, :drop), do: :ok
  def process_input(port, pty, transformed), do: port.command(pty, transformed)

  def handle_dsr_response(port, pty, data, _state) do
    {rows, cols} = Size.get_default()
    send_if_response(port, pty, Dsr.scan(data, rows, cols, ""))
  end

  defp send_if_response(port, pty, {response, _}) when response != "" do
    port.command(pty, response)
  end
  defp send_if_response(_, _, _), do: :ok
end
