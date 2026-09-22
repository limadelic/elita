defmodule Elita.Tick do
  import Supervisor, only: [which_children: 1]
  import Enum, only: [each: 2, filter: 2, map: 2]
  import Elita.Village, only: [fetch: 2]
  import Elita.Freeq, only: [tell: 3]
  import Now, only: [time: 0]
  import String, only: [pad_leading: 3]

  def tick(supervisor) do
    {{_, _, _}, {h, min, _}} = time()
    client = fetch(supervisor, "clock")
    msg = "[clock] it is #{pad(h)}:#{pad(min)}, what do you do or say"
    nicks(supervisor) |> each(&tell(client, &1, msg))
  end

  defp nicks(supervisor) do
    which_children(supervisor)
    |> filter(&valid(&1))
    |> map(&elem(&1, 0))
    |> map(&elem(&1, 1))
  end

  defp valid({id, _pid, _type, _modules}) do
    {Elita.Freeq, nick} = id
    nick != "clock"
  end

  defp pad(n), do: pad_leading(to_string(n), 2, "0")
end
