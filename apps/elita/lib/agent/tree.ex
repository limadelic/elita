defmodule Agent.Tree do
  import Supervisor, only: [start_link: 2]

  def start_link({name, configs, opts, via}) do
    start_link([session(name, configs, opts, via)], opts())
  end

  defp session(name, configs, opts, via),
    do: %{
      id: :session,
      start: launch(name, configs, opts, via),
      restart: :transient,
      significant: true
    }

  defp launch(name, configs, opts, via),
    do: {GenServer, :start_link, [Elita, {name, configs, opts}, [name: via]]}

  defp opts,
    do: [
      strategy: :rest_for_one,
      max_restarts: 3,
      max_seconds: 30,
      auto_shutdown: :any_significant
    ]
end
