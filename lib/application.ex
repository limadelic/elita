defmodule Elita.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ElitaRegistry}
    ]

    opts = [strategy: :one_for_one, name: Elita.Supervisor]
    Supervisor.start_link(children, opts)
  end
end