defmodule El.Command do
  @moduledoc false

  import IO, only: [puts: 1]
  import Node, only: [connect: 1]
  import :erpc, only: [call: 4]

  alias El.Commands.Ask
  alias El.Commands.Tell
  alias El.Commands.Claude
  alias El.Commands.Ls
  alias El.Distribution
  alias El.RPC

  def ls do
    Distribution.start()
    query() |> reach()
  end

  defp reach({:ok, output}), do: handle({:ok, output})
  defp reach(:error), do: attempt_spawn()

  defp attempt_spawn do
    System.get_env("EL_DAEMON_SPAWN") |> spawn_check()
  end

  defp spawn_check("1") do
    init()
    wait(0)
  end

  defp spawn_check(_), do: handle(:error)

  defp init do
    exe = pick()
    Port.open({:spawn_executable, "/bin/sh"}, [{:args, ["-c", "#{exe} daemon &"]}, :exit_status]) |> Port.close()
  end

  defp pick do
    System.find_executable("el") |> pick_result()
  end

  defp pick_result(nil), do: "#{File.cwd!()}/../../apps/el/el"
  defp pick_result(path), do: path

  defp wait(n) when n >= 10 do
    handle(:error)
  end

  defp wait(n) do
    Process.sleep(50 * (n + 1))
    query() |> wait_result(n)
  end

  defp wait_result({:ok, output}, _n), do: handle({:ok, output})
  defp wait_result(:error, n), do: wait(n + 1)

  defp handle({:ok, output}), do: puts(output)
  defp handle(:error), do: Ls.execute()

  def ask(agent, msg), do: Ask.execute(agent, msg)
  def tell(agent, msg), do: Tell.execute(agent, msg)
  def claude(name), do: Claude.execute(name)
  def daemon, do: Distribution.daemon()

  defp query do
    connect(:"elita@127.0.0.1") |> guard()
  end

  defp guard(bool) do
    fetch(bool)
  rescue
    _ -> :error
  end

  defp fetch(true) do
    cwd = File.cwd!()
    output = call(:"elita@127.0.0.1", RPC, :dispatch, [["ls"], cwd])
    {:ok, output}
  end

  defp fetch(_), do: :error
end
