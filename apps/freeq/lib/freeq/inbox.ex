defmodule Freeq.Inbox do
  import Freeq.Writer, only: [pong: 2]
  import Freeq.Answer, only: [privmsg: 3]
  import String, only: [contains?: 2, split: 3]
  import Freeq.Pending, only: [drop: 1, head: 1]
  import Freeq.Flood, only: [defer: 3]

  def route([], state), do: {:noreply, state}
  def route([line], state), do: handle(line, state)

  defp handle("PING " <> token, %{socket: socket} = state) do
    pong(socket, token)
    {:noreply, state}
  end

  defp handle(":" <> msg, %{socket: socket} = state) do
    dispatch(split(msg, " PING ", parts: 2), msg, socket, state)
  end

  defp handle(_msg, state), do: {:noreply, state}

  defp dispatch([server, token], msg, socket, state) do
    respond(contains?(server, " "), token, msg, socket, state)
  end

  defp dispatch([_], msg, _socket, state) do
    relay(check(msg), msg, state)
  end

  defp respond(false, token, _msg, socket, state) do
    pong(socket, token)
    {:noreply, state}
  end

  defp respond(true, _token, msg, _socket, state) do
    relay(check(msg), msg, state)
  end

  defp check(msg), do: check(contains?(msg, " 404 "), msg)

  defp check(false, _msg), do: false
  defp check(true, msg), do: contains?(msg, "Flood protection")

  defp relay(true, msg, state), do: {:noreply, defer(state, head(state), msg)}

  defp relay(false, msg, state) do
    answer(state, msg)
    {:noreply, settle(mine?(msg, state), state)}
  end

  defp answer(%{result: true}, _msg), do: :ok
  defp answer(state, msg), do: privmsg(msg, state, self())

  defp mine?(msg, %{agent: agent}), do: nick(msg) == agent

  defp nick(msg), do: msg |> split("!", parts: 2) |> hd()

  defp settle(true, state), do: drop(state)
  defp settle(false, state), do: state
end
