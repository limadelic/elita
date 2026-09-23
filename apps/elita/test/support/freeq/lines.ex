defmodule Freeq.Lines do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [map: 2, reject: 2, each: 2]

  def send(socket, channel, text) do
    lines = text |> split("\n") |> map(&trim/1) |> reject(&(&1 == ""))
    case lines do
      [single] -> single_message(socket, channel, single)
      batch_lines -> batch_message(socket, channel, batch_lines)
    end
  end

  defp single_message(socket, channel, text) do
    :gen_tcp.send(socket, "PRIVMSG #{channel} :#{text}\r\n")
  end

  defp batch_message(socket, channel, lines) do
    batch_id = unique_batch_id()
    :gen_tcp.send(socket, "BATCH +#{batch_id} draft/multiline #{channel}\r\n")
    each(lines, &send_batch_line(socket, channel, batch_id, &1))
    :gen_tcp.send(socket, "BATCH -#{batch_id}\r\n")
  end

  defp send_batch_line(socket, channel, batch_id, line) do
    :gen_tcp.send(socket, "@batch=#{batch_id} PRIVMSG #{channel} :#{line}\r\n")
  end

  defp unique_batch_id do
    time = System.monotonic_time(:microsecond)
    "b#{time}"
  end
end
