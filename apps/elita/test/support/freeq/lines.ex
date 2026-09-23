defmodule Freeq.Lines do
  import Freeq.Writer, only: [message: 3]
  def send(socket, channel, text), do: message(socket, channel, text)
end
