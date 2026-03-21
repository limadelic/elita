defmodule Elita.Application do
  @moduledoc """
  Starts `Registry` for named agents and the `:elita_agents` ETS table.

  `Elita` workers are **not** supervised here: they are started with `start_link`
  from the CLI or tools (e.g. spawn). If a worker crashes it stays down until
  restarted manually—appropriate for an interactive escript, not for unattended
  services.
  """

  use Application

  def start(_type, _args) do
    :ets.new(:elita_agents, [:set, :public, :named_table])

    children = [
      {Registry, keys: :unique, name: ElitaRegistry}
    ]

    opts = [strategy: :one_for_one, name: Elita.Supervisor]
    Supervisor.start_link(children, opts)
  end
end