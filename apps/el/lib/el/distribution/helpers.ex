defmodule El.Distribution.Helpers do
  import Node, only: [connect: 1]
  import Enum, only: [each: 2]
  import El.Peers, only: [load: 0]
  import El.Log, only: [write: 1]
  import Registry, only: [lookup: 2]
  import El.Run, only: [suffix: 0]

  def extract([{pid, %{kind: :puppet}}]), do: pid
  def extract(_), do: nil

  def route(result, name) when result in [true, :ignored], do: locate(name)
  def route(false, name), do: find(name)

  def dial do
    load() |> each(&connect/1)
  rescue
    _ -> :ok
  end

  def attach(name) do
    connect(:"#{name}#{suffix()}@127.0.0.1")
    :global.sync()
  end

  def locate(name) do
    a = :"#{name}#{suffix()}@127.0.0.1"
    write("connect #{a}: #{inspect(connect(a))}\n")
    :global.sync()
    :global.whereis_name({name, :puppet}) |> reply(name)
  end

  def find(name) do
    lookup(ElitaRegistry, name) |> extract()
  rescue
    _ -> nil
  end

  defp reply(:undefined, name) do
    write("whereis_name #{name}: :undefined\n")
    find(name)
  end

  defp reply(pid, name) do
    write("whereis_name #{name}: #{inspect(pid)}\n")
    pid
  end
end
