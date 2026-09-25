defmodule Freeq.Resident do
  import DynamicSupervisor, only: [start_child: 2]
  import Kernel, except: [spawn: 3]
  import Elita, only: [spawn: 3]

  def start(agent, channel, host, port, opts \\ %{}) do
    setup = [kind: Freeq.Kind, tape_env: opts]
    {:ok, pid} = spawn(agent, [agent], setup)
    {:ok, freeq} = boot(agent, channel, host, port, setup)
    {:ok, pid, freeq}
  end

  defp boot(name, channel, host, port, setup),
    do: start_child(Elita.Spawner,
                    {Freeq, [agent: name, channel: channel, host: host,
                             port: port, config: setup]})
end
