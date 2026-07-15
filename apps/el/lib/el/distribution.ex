defmodule El.Distribution do
  import Application, only: [ensure_all_started: 1]
  import Process, only: [sleep: 1]
  import Node, only: [connect: 1, alive?: 0, start: 2]
  import El.Boot, only: [go: 2]
  import El.Distribution.Helpers
  import El.Run, only: [address: 0, suffix: 0]

  def start(name \\ :default), do: run(name, [])

  defp run(name, opts), do: go(name, opts)

  def bind(_name) do
    :ok
  end

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
    go(name, tries, locate(name), alive?())
  end

  defp loop(_name, 0), do: nil

  defp go(_name, _tries, pid, true) when is_pid(pid) do
    pid
  end

  defp go(name, tries, _pid, _) when tries > 1 do
    sleep(100)
    loop(name, tries - 1)
  end

  defp go(_name, _tries, _pid, _), do: nil

  def daemon do
    boot(address())
    ensure_all_started(:elita)
    dial()
    sleep(:infinity)
  end

  defp boot(addr) do
    start(addr, :longnames)
  end
end
