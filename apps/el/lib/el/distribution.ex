defmodule El.Distribution do
  import Application, only: [ensure_all_started: 1]
  import Process, only: [sleep: 1]
  import Node, only: [connect: 1, start: 2]
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
    :net_kernel.monitor_nodes(true)
    name |> node() |> retry(name, 50)
  after
    :net_kernel.monitor_nodes(false)
  end

  defp node(name) do
    :"#{name}#{suffix()}@127.0.0.1"
  end

  defp retry(target, name, tries) when tries > 0 do
    attach(name)
    result(locate(name), name, target, tries)
  end

  defp retry(_target, _name, _tries), do: nil

  defp result(pid, _name, _target, _tries) when is_pid(pid) do
    pid
  end

  defp result(_pid, name, target, tries) do
    receive do
      {:nodeup, ^target} ->
        :global.sync()
        retry(target, name, tries - 1)
    after
      100 ->
        retry(target, name, tries - 1)
    end
  end

  def daemon do
    boot(address())
    ensure_all_started(:elita)
    dial()
    sleep(:infinity)
  end

  defp boot(addr) do
    :os.cmd(~c"epmd -daemon")
    start(addr, :longnames)
  end
end
