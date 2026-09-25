defmodule Freeq.Welcome do
  import String, only: [trim_trailing: 2, contains?: 2, split: 1]
  import Enum, only: [at: 3]

  def greet(socket) do
    receive do
      {:tcp, ^socket, line} -> check(line, socket, 0)
      {:tcp_closed, ^socket} -> raise "Socket closed waiting for 001"
    after
      5000 -> raise("Timeout waiting for 001: no lines received")
    end
  end

  defp check(line, socket, count) do
    str = line |> to_string() |> trim_trailing("\r\n")
    s433 = contains?(str, " 433 ")
    s001 = contains?(str, " 001 ")
    status(s433, s001) |> proceed(socket, str, count)
  end

  defp status(true, _), do: :nick_taken
  defp status(false, true), do: :ok
  defp status(false, false), do: :continue

  defp proceed(:nick_taken, _socket, str, _count) do
    raise "nick #{nick(str)} in use"
  end

  defp proceed(:ok, _socket, _last, _count), do: :ok

  defp proceed(:continue, socket, last, count) do
    loop(socket, last, count)
  end

  defp loop(socket, last, count) do
    receive do
      {:tcp, ^socket, line} -> check(line, socket, count)
      {:tcp_closed, ^socket} -> raise "Socket closed waiting for 001"
    after
      5000 -> raise("Timeout waiting for 001: Last line: #{last} (#{count} lines received)")
    end
  end

  defp nick(str) do
    str |> split() |> at(3, "unknown")
  end
end
