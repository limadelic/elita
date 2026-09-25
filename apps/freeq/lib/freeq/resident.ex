defmodule Freeq.Resident do
  import DynamicSupervisor, only: [start_child: 2]
  import GenServer, only: [stop: 1]
  import Kernel, except: [spawn: 3]
  import Elita, only: [spawn: 3]
  import Map, only: [get: 3, drop: 2]

  def start(agent, channel, host, port, opts \\ %{}) do
    cfg = setup(opts)
    name = to_string(agent)
    boot = fn -> boot(name, channel, host, port, cfg) end
    started(spawn(name, [name], opt(cfg, get(opts, :cwd, nil))), boot)
  end

defp started({:ok, pid}, boot) do
    result(boot.(), pid)
  end

  defp started({:error, err}, _boot) do
    {:error, split(err)}
  end

  defp split({:shutdown, info}) do
    child(info)
  end

  defp split(other) do
    to_string(other)
  end

  defp child({:failed_to_start_child, _, {%{message: msg}, _}}) do
    msg
  end

  defp child(_) do
    "unknown error"
  end

  defp opt(cfg, nil), do: cfg
  defp opt(cfg, cwd), do: cfg ++ [cwd: cwd]

  defp result({:ok, freeq}, pid), do: {:ok, pid, freeq}
  defp result({:error, {%{message: msg}, _}}, pid)
       when is_binary(msg) do
    stop(pid)
    {:error, msg}
  end
  defp result({:error, error}, pid) do
    stop(pid)
    {:error, to_string(error)}
  end

  defp setup(opts) when map_size(opts) == 0, do: [kind: Freeq.Kind]
  defp setup(opts), do: [kind: Freeq.Kind, tape_env: drop(opts, [:cwd])]

  defp boot(name, channel, host, port, setup) do
    start_child(Elita.Spawner,
                {Freeq, [agent: name, channel: channel, host: host,
                         port: port, config: setup]})
  end
end
