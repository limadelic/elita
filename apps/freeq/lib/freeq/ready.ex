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
    c366 = contains?(str, " 366 ")
    c473 = contains?(str, " 473 ")
    {c366, c473} |> classify(socket, str, count + 1)
  end

  defp classify({true, _}, _socket, _last, _count), do: :ok
  defp classify({_, true}, _socket, _last, _count), do: :invite
  defp classify({false, false}, socket, last, count) do
    await(socket, last, count)
  end

  defp text(0, _), do: "no lines received"
  defp text(count, last), do: "Last line: #{last} (#{count} lines received)"
end
