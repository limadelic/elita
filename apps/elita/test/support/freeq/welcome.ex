defmodule Freeq.Welcome do
  import String, only: [trim_trailing: 2, contains?: 2]

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
    contains?(str, " 001 ") |> ready(socket, str, count + 1)
  end

  defp ready(true, _socket, _last, _count), do: :ok
  defp ready(false, socket, last, count), do: loop(socket, last, count)

  defp loop(socket, last, count) do
    receive do
      {:tcp, ^socket, line} -> check(line, socket, count)
      {:tcp_closed, ^socket} -> raise "Socket closed waiting for 001"
    after
      5000 -> raise("Timeout waiting for 001: Last line: #{last} (#{count} lines received)")
    end
  end
end
