defmodule Elita.Freeq.Lines do
  import String, only: [split: 2, trim: 1, trim_trailing: 2]
  import Enum, only: [flat_map: 2, reject: 2, each: 2]
  import Elita.Freeq.Writer, only: [message: 3]

  def send(socket, channel, text) do
    text
    |> split("\n")
    |> flat_map(&sieve/1)
    |> each(&message(socket, channel, &1))
  end

  defp sieve(line) do
    [trim_trailing(line, "\r")] |> reject(fn l -> trim(l) == "" end)
  end
end
