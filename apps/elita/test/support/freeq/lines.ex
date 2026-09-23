defmodule Freeq.Lines do
  import String, only: [split: 2, trim: 1, trim_trailing: 2]
  import Enum, only: [map: 2, reject: 2, each: 2]
  import Freeq.Writer, only: [message: 3]

  def send(socket, channel, text), do: text |> lines() |> each(&message(socket, channel, &1))

  defp lines(text), do: text |> split("\n") |> map(&trim_trailing(&1, "\r")) |> reject(&empty?/1)

  defp empty?(line), do: trim(line) == ""
end
