defmodule Elita.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ElitaRegistry},
      :hackney_pool.child_spec(:default, timeout: 15_000, max_connections: 100)
    ]

    opts = [strategy: :one_for_one, name: Elita.Supervisor]
    result = Supervisor.start_link(children, opts)
    warmup()
    result
  end

  defp warmup do
    Lite.llm("warmup")
  end
end