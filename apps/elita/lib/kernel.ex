defmodule Elita.Kernel do
  import Registry, only: [child_spec: 1]
  import Supervisor, only: [start_link: 2]

  def start_link(_arg) do
    start_link(specs(), opts())
  end

  defp specs,
    do: [
      child_spec(keys: :unique, name: ElitaRegistry),
      {DynamicSupervisor, spec()}
    ]

  defp spec,
    do: [
      name: Elita.Spawner,
      strategy: :one_for_one,
      max_restarts: 3,
      max_seconds: 30
    ]

  defp opts,
    do: [
      strategy: :rest_for_one,
      name: Elita.Kernel,
      max_restarts: 3,
      max_seconds: 30
    ]
end
