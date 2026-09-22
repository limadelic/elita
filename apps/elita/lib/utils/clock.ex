defmodule Clock do
  import Enum, only: [each: 2]
  import Now, only: [time: 0]
  import Elita.Village, only: [fetch: 2]
  import Elita.Freeq, only: [tell: 3]
  import String, only: [pad_leading: 3]

  def now do
    {{2025, 7, 7}, {10, 0, 0}}
  end

  def tick(supervisor) do
    {{_y, _m, _d}, {h, min, _s}} = time()
    msg = "[clock] it is #{pad(h)}:#{pad(min)}, what do you do or say"
    villagers = ["isabella", "worker"]
    each(villagers, &send(&1, supervisor, msg))
  end

  defp send(nick, supervisor, msg) do
    fetch(supervisor, nick) |> tell("clock", msg)
  end

  defp pad(n), do: pad_leading(to_string(n), 2, "0")
end
