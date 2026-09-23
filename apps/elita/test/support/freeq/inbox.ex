defmodule Freeq.Inbox do
  import Freeq.Writer, only: [pong: 2]
  import Freeq.Answer, only: [privmsg: 3]
  import String, only: [contains?: 2]

  def route([], state), do: {:noreply, state}
  def route([line], state), do: handle(line, state)

  defp handle("PING " <> server, %{socket: socket} = state) do
    pong(socket, server)
    {:noreply, state}
  end

  defp handle(":" <> msg, state), do: relay(refused?(msg), msg, state)

  defp handle(_msg, state), do: {:noreply, state}

  defp refused?(msg), do: contains?(msg, " 404 ") and contains?(msg, "Flood protection")

  defp relay(true, msg, _state), do: raise("freeq refused a message: #{msg}")

  defp relay(false, msg, state) do
    privmsg(msg, state, self())
    {:noreply, state}
  end
end
