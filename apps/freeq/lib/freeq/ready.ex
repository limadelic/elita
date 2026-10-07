defmodule Freeq.Ready do
  import String, only: [trim_trailing: 2, contains?: 2]

  def wait(socket, channel) do
    await(socket, channel, "", 0)
  end

  defp await(socket, channel, last, count) do
    receive do
      {:tcp, ^socket, line} -> check(line, socket, channel, count)
      {:tcp_closed, ^socket} -> raise "Socket closed waiting for 366"
    after
      5000 -> raise("Timeout waiting for 366: #{text(count, last)}")
    end
  end

  defp check(line, socket, channel, count) do
    str = line |> to_string() |> trim_trailing("\r\n")
    mark = " #{channel} :"
    {contains?(str, " 366 "), contains?(str, " 473 "), contains?(str, mark)}
    |> classify(socket, channel, str, count + 1)
  end

  defp classify({true, _, true}, _socket, _channel, _last, _count), do: :ok
  defp classify({_, true, true}, _socket, _channel, _last, _count), do: :invite
  defp classify(_, socket, channel, last, count) do
    await(socket, channel, last, count)
  end

  defp text(0, _), do: "no lines received"
  defp text(count, last), do: "Last line: #{last} (#{count} lines received)"
end
