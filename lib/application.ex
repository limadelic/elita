defmodule Elita.Application do
  @moduledoc """
  Starts `Registry`, `DynamicSupervisor`, and the `:elita_agents` ETS table.

  Every `Elita` agent is started under `Elita.AgentSupervisor` via
  `Elita.start/2`. OTP restarts crashed agents automatically (`:transient`
  strategy — crashes restart, clean shutdowns stay down).
  """

  use Application

  def start(_type, _args) do
    :ets.new(:elita_agents, [:set, :public, :named_table])

    children = [
      {Registry, keys: :unique, name: ElitaRegistry},
      {DynamicSupervisor, name: Elita.AgentSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: Elita.Supervisor]
    Supervisor.start_link(children, opts)
  end
end