defmodule Elita.Boot do
  import GenServer, only: [call: 3, cast: 2, start: 3]
  import Kernel, except: [spawn: 3]
  import Application, only: [get_env: 3]
  import Elita.Boot.Announce, only: [notify: 2]
  import Utils.Normalize, only: [name: 1]
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
    there(name, configs, opts, get_env(:elita, :clock_override, nil))
  end

  defp boot(name, configs, opts, false) do
    local(name, configs, opts)
  end

  defp there(name, configs, opts, nil), do: fetch(addr(), name, configs, opts)

  defp there(name, configs, opts, val),
    do: addr() |> tap(&push(&1, val)) |> fetch(name, configs, opts)

  defp fetch(addr, name, configs, opts) do
    addr |> start(spec(name, configs, opts)) |> enroll(name, addr)
  catch
    _, _ -> local(name, configs, opts)
  end

  defp push(addr, val) do
    :erpc.call(addr, Application, :put_env, [:elita, :clock_override, val], 5000)
  catch
    _, _ -> :ok
  end

  defp spec(name, configs, opts),
    do: %{id: name, start: launch(name, configs, opts), restart: :temporary}

  defp launch(name, configs, opts) do
    args = [Elita, {name, configs, opts}, [name: via(name)]]
    {GenServer, :start_link, args}
  end

  defp start(addr, spec),
    do: :erpc.call(addr, DynamicSupervisor, :start_child, [Elita.Spawner, spec], 90_000)

  defp enroll({:ok, pid}, n, addr) do
    :erpc.call(addr, :global, :register_name, [{name(n), :puppet}, pid], 5000)
    notify(n, pid)
    {:ok, pid}
  end

  defp enroll({:error, {:already_started, pid}}, _n, _addr), do: {:ok, pid}
  defp enroll(other, _n, _addr), do: other

  defp addr, do: :"elita-#{get_env(:elita, :run, "")}@127.0.0.1"

  defp local(n, configs, opts) do
    start(Elita, {n, configs, opts}, name: via(n)) |> join() |> keep(n)
  end

  defp keep({:ok, pid}, n) do
    :global.whereis_name({name(n), :puppet}) |> reg(n, pid)
    {:ok, pid}
  end

  defp keep(err, _), do: err

  defp ready?, do: get_env(:elita, :run, "") != ""

  defp join({:ok, p}), do: {:ok, p}
  defp join({:error, {:already_started, p}}), do: {:ok, p}

  defp join({:error, {exc, _stack}}) when is_exception(exc) do
    {:error, {:init_failed, exc.message}}
  end

  defp join({:error, _}), do: {:error, :init_failed}

  defp reg(:undefined, n, pid), do: :global.register_name({name(n), :puppet}, pid)
  defp reg(_, _, _), do: :ok

  defp via(n) do
    {:via, Registry, {ElitaRegistry, name(n), %{kind: :native, folder: nil}}}
  end
end
