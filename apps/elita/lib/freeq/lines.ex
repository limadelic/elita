defmodule Elita.Freeq.Lines do
  import String, only: [split: 2, trim: 1, trim_trailing: 2]
  import Enum, only: [reject: 2, each: 2, map: 2]
  import Elita.Freeq.Writer, only: [message: 3]

  def send(socket, channel, text) do
    text |> split("\n") |> dispatch(socket, channel)
  end

  defp dispatch(lines, socket, channel) do
    cleaned = lines |> map(&strip/1) |> reject(&empty?/1)
    cleaned |> each(&message(socket, channel, &1))
  end

  defp strip(line) do
    line
    |> trim_trailing("\r")
    |> trim()
  end

  defp empty?(line) do
    line == ""
  end
end
