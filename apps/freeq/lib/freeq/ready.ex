defmodule Freeq.Ready do
  import String, only: [trim_trailing: 2, contains?: 2]

  def wait(socket) do
    await(socket, "", 0)
  end

  defp await(socket, last, count) do
    receive do
      {:tcp, ^socket, line} -> check(line, socket, count)
      {:tcp_closed, ^socket} -> raise "Socket closed waiting for 366"
    after
      5000 -> raise("Timeout waiting for 366: #{text(count, last)}")
    end
  end

  defp check(line, socket, count) do
    str = line |> to_string() |> trim_trailing("\r\n")
    contains?(str, " 366 ") |> ready(socket, str, count + 1)
  end

  defp ready(true, _socket, _last, _count), do: :ok
  defp ready(false, socket, last, count), do: await(socket, last, count)

  defp text(0, _), do: "no lines received"
  defp text(count, last), do: "Last line: #{last} (#{count} lines received)"
end
