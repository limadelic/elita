defmodule El.Distribution do
  import Application, only: [ensure_all_started: 1]
  import El.Peers, only: [load: 0]
  import Process, only: [sleep: 1]
  import Node, only: [connect: 1]
  import Enum, only: [each: 2]
  import Registry, only: [lookup: 2]

  defdelegate start(name \\ :default, opts \\ []), to: El.Boot

  def target(name) do
    connect(:"#{name}@127.0.0.1") |> route(name)
  rescue
    _ -> find(name)
  end

  def wait(name) do
    loop(name, 50)
  end

  defp loop(name, tries) when tries > 0 do
    attach(name)
    go(name, tries, locate(name), Node.alive?())
  end

  defp loop(_name, 0) do
    nil
  end

  defp attach(name) do
    connect(:"#{name}@127.0.0.1")
    :global.sync()
  end

  defp go(_name, _tries, pid, true) when is_pid(pid) do
    pid
  end

  defp go(name, tries, _pid, _) when tries > 1 do
    sleep(100)
    :global.sync()
    loop(name, tries - 1)
  end

  defp go(_name, _tries, _pid, _) do
    nil
  end

  defp route(result, name) when result in [true, :ignored], do: locate(name)
  defp route(false, name), do: find(name)

  defp locate(name) do
    :global.sync()
    :global.whereis_name({name, :puppet}) |> reply(name)
  end

  defp reply(:undefined, name), do: find(name)
  defp reply(pid, _name), do: pid

  defp find(name) do
    lookup(ElitaRegistry, name) |> extract()
  rescue
    _ -> nil
  end

  defp extract([{pid, %{kind: :puppet}}]), do: pid
  defp extract(_), do: nil

  def daemon do
    Node.start(:"elita@127.0.0.1", :longnames)
    ensure_all_started(:elita)
    dial()
    sleep(:infinity)
  end

  defp dial do
    load() |> each(&connect/1)
  rescue
    _ -> :ok
  end
end
