defmodule Elita.Application do
  use Application

  import Agent.Manager, only: [launch: 0]
  import Elita, only: [prime: 0]
  import Elita.Ready, only: [up: 0]
  import Mem, only: [setup: 0]
  import Supervisor, only: [start_link: 2]
  import Sweep, only: [sweep: 0]

  def start(_type, _args) do
    setup()
    sweep()
    boot()
  end

  defp boot do
    {:ok, supervisor} = run()
    launch()
    finish()
    {:ok, supervisor}
  end

  defp finish do
    {:ok, _} = prime()
    up()
  end

  defp run do
    start_link(specs(), opts())
  end

  defp specs,
    do: [
      {Elita.Kernel, nil},
      {Elita.Infra, nil},
      {Task.Supervisor, name: Elita.Tasks}
    ]

  defp opts,
    do: [
      strategy: :one_for_one,
      name: Elita.Supervisor,
      max_restarts: 3,
      max_seconds: 60
    ]
end
