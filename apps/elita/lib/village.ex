defmodule Elita.Village do
  import Supervisor, only: [start_link: 3, child_spec: 2, init: 2]
  import Keyword, only: [fetch!: 2]
  import Elita, only: [spawn: 2]
  import Enum, only: [each: 2, map: 2]

  def start_link(opts) do
    cast = fetch!(opts, :cast)
    channel = fetch!(opts, :channel)
    start_link(__MODULE__, {cast, channel}, [])
  end

  def init({cast, channel}) do
    each(cast, &boot(&1))
    children = map(cast, &client(&1, channel))
    init(children, strategy: :one_for_one)
  end

  defp boot(name) do
    spawn(to_string(name), [to_string(name)])
  end

  defp client(name, channel) do
    n = to_string(name)
    spec = {Elita.Freeq, [agent: n, channel: channel]}
    child_spec(spec, id: {Elita.Freeq, n})
  end
end
