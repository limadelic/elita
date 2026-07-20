defmodule Elita.Boot do
  import GenServer, only: [call: 3, cast: 2, start: 3]
  import Kernel, except: [spawn: 3]
  import String, only: [downcase: 1]
  import System, only: [get_env: 2]

  def spawn(name, configs, opts \\ [])
  def spawn(name, configs, []), do: boot(name, configs, sender: name)
  def spawn(name, configs, opts), do: boot(name, configs, opts)

  def prime, do: spawn("el", ["el"], skip_logs: true)

  def dispatch(name, msg) do
    cast(via(name), {:act, msg})
  end

  def request(name, msg) do
    call(via(name), {:act, msg}, :infinity)
  end

  defp boot(name, configs, opts) do
    boot(name, configs, opts, ready?())
  end

  defp boot(name, configs, opts, true) do
    there(name, configs, opts)
  end

  defp boot(name, configs, opts, false) do
    local(name, configs, opts)
  end

  defp there(name, configs, opts) do
    fetch(addr(), name, configs, opts)
  end

  defp fetch(addr, name, configs, opts) do
    spec = {Elita, {name, configs, opts}, [name: via(name)]}
    :erpc.call(addr, DynamicSupervisor, :start_child, [Elita.Spawner, spec], 5000)
  rescue
    _ -> local(name, configs, opts)
  end

  defp addr do
    id = get_env("ELITA_RUN", "")
    :"elita-#{id}@127.0.0.1"
  end

  defp local(name, configs, opts) do
    {:ok, pid} = started(Elita, {name, configs, opts}, via(name))
    :global.whereis_name({name, :puppet}) |> reg(name, pid)
    {:ok, pid}
  end

  defp ready? do
    get_env("ELITA_RUN", "") != ""
  end

  defp started(m, a, k) do
    engine(m, a, k)
  end

  defp engine(m, a, k) do
    start(m, a, name: k) |> join()
  end

  defp join({:ok, p}), do: {:ok, p}
  defp join({:error, {:already_started, p}}), do: {:ok, p}

  defp reg(:undefined, name, pid), do: :global.register_name({name, :puppet}, pid)
  defp reg(_, _, _), do: :ok

  defp via(name) do
    normalized = name |> to_string() |> downcase()
    {:via, Registry, {ElitaRegistry, normalized, %{kind: :native, folder: nil}}}
  end
end
