defmodule Elita.Application do
  use Application

  def start(_type, _args) do
    Mem.init_global()
    Supervisor.start_link(children(), opts())
  end

  defp children do
    [{Registry, keys: :unique, name: ElitaRegistry}]
  end

  defp opts do
    [strategy: :one_for_one, name: Elita.Supervisor]
  end
end