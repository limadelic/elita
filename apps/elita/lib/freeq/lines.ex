defmodule Elita.Freeq.Lines do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [reject: 2, each: 2]
  import Elita.Freeq.Writer, only: [message: 3]

  def send(socket, channel, text) do
    text
    |> split("\n")
    |> reject(&empty?/1)
    |> each(&message(socket, channel, &1))
  end

  defp empty?(line) do
    trim(line) == ""
  end
end
