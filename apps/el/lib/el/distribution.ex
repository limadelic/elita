defmodule El.Distribution do
  import Application, only: [ensure_all_started: 1]
  import Process, only: [sleep: 1]
  import Node, only: [connect: 1]
  import El.Log, only: [write: 1]
  import El.Distribution.Helpers
  import El.Run, only: [address: 0, suffix: 0]

  defdelegate start(name \\ :default, opts \\ []), to: El.Boot

  def bind(name), do: bind(name, 50)

  defp bind(name, tries) when tries > 0 do
    go(name, tries, find(name))
  end

  defp bind(_name, 0), do: :ok

  defp go(name, _tries, pid) when is_pid(pid) do
    result = sync(name, pid)
    write("global register #{name}: #{inspect(result)} node=#{inspect(Node.self())}\n")
    result
  end

  defp go(name, tries, nil) do
    sleep(100)
    bind(name, tries - 1)
  end

  defp sync(name, pid) do
    sync(name, pid, :global.whereis_name({name, :puppet}))
  end

  defp sync(name, pid, :undefined) do
    :global.register_name({name, :puppet}, pid)
  end

  defp sync(_name, _pid, _existing), do: :yes

  def target(name) do
    connect(:"#{name}#{suffix()}@127.0.0.1") |> route(name)
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

  defp loop(_name, 0), do: nil

  defp go(_name, _tries, pid, true) when is_pid(pid) do
    pid
  end

  defp go(name, tries, _pid, _) when tries > 1 do
    sleep(100)
    :global.sync()
    loop(name, tries - 1)
  end

  defp go(_name, _tries, _pid, _), do: nil

  def daemon do
    Node.start(address(), :longnames)
    ensure_all_started(:elita)
    dial()
    sleep(:infinity)
  end
end
