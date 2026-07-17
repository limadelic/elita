defmodule Elita.Boot do
  import GenServer, only: [call: 3, cast: 2, start_link: 3]
  import Kernel, except: [spawn: 3]
  import String, only: [downcase: 1]

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
    {:ok, pid} = started(Elita, {name, configs, opts}, via(name))
    :global.whereis_name({name, :puppet}) |> reg(name, pid)
    {:ok, pid}
  end

  defp started(m, a, k) do
    start_link(m, a, name: k) |> join()
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
