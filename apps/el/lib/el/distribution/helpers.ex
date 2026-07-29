defmodule El.Distribution.Helpers do
  import Node, only: [connect: 1]
  import El.Trace, only: [write: 1]
  import Registry, only: [lookup: 2]
  import El.Run, only: [suffix: 0]
  import Utils.Normalize, only: [name: 1]

  def extract([{pid, %{kind: :puppet}}]), do: pid
  def extract(_), do: nil

  def route(result, name) when result in [true, :ignored], do: locate(name)
  def route(false, name), do: find(name)

  def attach(name) do
    connect(:"#{name}#{suffix()}@127.0.0.1")
    :ok = :global.sync()
  end

  def locate(n) do
    a = :"#{n}#{suffix()}@127.0.0.1"
    write("connect #{a}: #{inspect(connect(a))}\n")
    :ok = :global.sync()
    :global.whereis_name({name(n), :puppet}) |> reply(n)
  end

  def find(n) do
    lookup(ElitaRegistry, name(n)) |> extract()
  rescue
    ArgumentError -> nil
  end

  defp reply(:undefined, n) do
    write("whereis_name #{n}: :undefined\n")
    find(n)
  end

  defp reply(pid, n) do
    write("whereis_name #{n}: #{inspect(pid)}\n")
    pid
  end
end
