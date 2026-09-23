defmodule Freeq.Lines do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [map: 2, reject: 2, join: 2]
  import Freeq.Writer, only: [message: 3]

  def send(socket, channel, text), do: message(socket, channel, flat(text))

  defp flat(text), do: text |> split("\n") |> map(&trim/1) |> reject(&(&1 == "")) |> join(" ")
end
