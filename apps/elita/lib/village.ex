defmodule Elita.Village do
  import Supervisor,
    only: [start_link: 3, child_spec: 2, init: 2, which_children: 1]

  import Keyword, only: [fetch!: 2]
  import Elita, only: [spawn: 2]
  import Enum, only: [each: 2, map: 2, find: 2]

  def start_link(opts) do
    cast = fetch!(opts, :cast)
    channel = fetch!(opts, :channel)
    start_link(__MODULE__, {cast, channel}, [])
  end

  def fetch(supervisor, name) do
    to_string(name)
    |> then(&lookup(supervisor, &1))
  end

  defp lookup(supervisor, name) do
    which_children(supervisor)
    |> find(&match({Elita.Freeq, name}, &1))
    |> elem(1)
  end

  defp match(expected, {id, _pid, _type, _modules}) do
    id == expected
  end

  def init({cast, channel}) do
    each(cast, &boot(&1))
    children = map(cast, &client(&1, channel))
    init(children, strategy: :one_for_one)
  end

  defp boot(name) do
    {:ok, _pid} = spawn(to_string(name), [to_string(name)])
  end

  defp client(name, channel) do
    n = to_string(name)
    spec = {Elita.Freeq, [agent: n, channel: channel]}
    child_spec(spec, id: {Elita.Freeq, n})
  end
end
