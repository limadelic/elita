defmodule Freeq.Resident do
  import DynamicSupervisor, only: [start_child: 2]
  import Kernel, except: [spawn: 3]
  import Elita, only: [spawn: 3]
  def start(agent, channel, host, port, opts \\ %{}) do
    cfg = setup(opts)
    {:ok, pid} = spawn(to_string(agent), [to_string(agent)], cfg)
    {:ok, freeq} = boot(to_string(agent), channel, host, port, cfg)
    {:ok, pid, freeq}
  end

  defp setup(opts) when map_size(opts) == 0, do: [kind: Freeq.Kind]
  defp setup(opts), do: [kind: Freeq.Kind, tape_env: opts]

  defp boot(name, channel, host, port, setup),
    do: start_child(Elita.Spawner,
                    {Freeq, [agent: name, channel: channel, host: host,
                             port: port, config: setup]})
end
