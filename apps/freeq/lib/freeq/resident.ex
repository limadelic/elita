defmodule Freeq.Resident do
  import DynamicSupervisor, only: [start_child: 2]
  import Kernel, except: [spawn: 3]
  import Elita, only: [spawn: 3]

  def start(agent, channel, host, port, driver \\ nil) do
    name = to_string(agent)
    {:ok, pid} = spawn(name, [name], kind: Freeq.Kind)
    {:ok, freeq} = boot(name, channel, driver, host, port)
    {:ok, pid, freeq}
  end

  defp boot(name, channel, driver, host, port) do
    start_child(Elita.Spawner, {Freeq, [
      agent: name, channel: channel, driver: driver, host: host, port: port
    ]})
  end
end
