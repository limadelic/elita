defmodule Elita.Kernel do
  import Supervisor, only: [start_link: 2]

  defdelegate registry_spec(opts), to: Registry, as: :child_spec

  @spec_map %{
    id: __MODULE__,
    start: {__MODULE__, :start_link, [nil]},
    type: :supervisor,
    restart: :permanent,
    shutdown: :infinity
  }

  def child_spec(_arg), do: @spec_map

  def start_link(_arg) do
    start_link(specs(), opts())
  end

  defp specs,
    do: [
      registry(),
      Elita.Bank,
      {DynamicSupervisor, spec()}
    ]

  defp registry do
    registry_spec(keys: :unique, name: ElitaRegistry)
  end

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
      max_seconds: 60
    ]
end
