defmodule Freeq.Welcome do
  import String, only: [trim_trailing: 2, contains?: 2, split: 1]
  import Enum, only: [at: 3]

  def greet(socket, nick) do
    receive do
      {:tcp, ^socket, line} -> check(line, socket, nick, 0)
      {:tcp_closed, ^socket} -> raise "Socket closed waiting for 001"
    after
      5000 -> raise("Timeout waiting for 001: no lines received")
    end
  end

  defp check(line, socket, nick, count) do
    str = line |> to_string() |> trim_trailing("\r\n")
    status(contains?(str, " 433 "), contains?(str, " 001 "), nick, str)
    |> proceed(socket, str, count, nick)
  end

  defp status(true, _, nick, _), do: {:error, "nick #{nick} in use"}
  defp status(false, true, nick, str), do: verify(nick, target(str))
  defp status(false, false, _, _), do: :continue

  defp verify(nick, received_nick) when nick == received_nick, do: :ok
  defp verify(nick, _), do: {:error, "nick #{nick} in use"}

  defp proceed({:error, reason}, _socket, _str, _count, _nick) do
    {:error, reason}
  end

  defp proceed(:ok, _socket, _last, _count, _nick), do: :ok

  defp proceed(:continue, socket, last, count, nick) do
    loop(socket, last, count, nick)
  end

  defp loop(socket, last, count, nick) do
    receive do
      {:tcp, ^socket, line} -> check(line, socket, nick, count)
      {:tcp_closed, ^socket} -> raise "Socket closed waiting for 001"
    after
      5000 -> raise(timeout(last, count))
    end
  end

  defp timeout(last, count) do
    "Timeout waiting for 001: Last line: #{last} (#{count} lines received)"
  end

  defp target(str) do
    str |> split() |> at(2, "unknown")
  end
end
