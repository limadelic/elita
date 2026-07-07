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

  def ls(path \\ nil) do
    Distribution.start()
    query(path) |> reach(path)
  end

  defp reach({:ok, output}, _path), do: handle({:ok, output})
  defp reach(:error, path), do: spawn_daemon(path)

  defp spawn_daemon(path) do
    System.get_env("EL_DAEMON_SPAWN") |> gate(path)
  end

  defp gate("1", path) do
    init()
    wait(0, path)
  end

  defp gate(_, path), do: handle(:error, path)

  defp init do
    exe = pick()
    Port.open({:spawn_executable, "/bin/sh"}, [{:args, ["-c", "#{exe} daemon &"]}, :exit_status]) |> Port.close()
  end

  defp pick do
    System.find_executable("el") |> resolve()
  end

  defp resolve(nil), do: "#{File.cwd!()}/../../apps/el/el"
  defp resolve(path), do: path

  defp wait(n, path) when n >= 10 do
    handle(:error, path)
  end

  defp wait(n, path) do
    Process.sleep(50 * (n + 1))
    query(path) |> settle(n, path)
  end

  defp settle({:ok, output}, _n, _path), do: handle({:ok, output})
  defp settle(:error, n, path), do: wait(n + 1, path)

  defp handle({:ok, output}), do: puts(output)
  defp handle(:error, path), do: Ls.execute(path: path)

  def ask(agent, msg), do: Ask.execute(agent, msg)
  def tell(agent, msg), do: Tell.execute(agent, msg)
  def claude(name), do: Claude.execute(name)
  def daemon, do: Distribution.daemon()

  defp query(path) do
    connect(:"elita@127.0.0.1") |> guard(path)
  end

  defp guard(bool, path) do
    fetch(bool, path)
  rescue
    _ -> :error
  end

  defp fetch(true, path) do
    cwd = File.cwd!()
    cmd = pick_cmd(path)
    output = call(:"elita@127.0.0.1", RPC, :dispatch, [cmd, cwd])
    {:ok, output}
  end

  defp fetch(_, _), do: :error

  defp pick_cmd(nil), do: ["ls"]
  defp pick_cmd(path), do: ["ls", path]
end
