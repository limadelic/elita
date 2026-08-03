defmodule Matrix.Pty do
  @moduledoc false
  use GenServer

  import Keyword, only: [get: 2, get: 3]
  import Process, except: [alias: 1, info: 2, get: 2, get: 3]

  import Matrix.Pty.Init, only: [call: 1]
  import Matrix.Pty.Config, only: [build: 2, finalize: 2]
  import Matrix.Pty.Dispatch, only: [info: 2, reply: 2, relay: 2]
  import GenServer, only: [start_link: 3, call: 2, cast: 2]

  def boot(name, cmd, opts \\ []) do
    start_link(__MODULE__, {name, cmd, opts}, name: name)
  end

  def inject(name, message) do
    cast(name, {:inject, message})
  end

  def watch(name, pid) do
    call(name, {:tap, pid})
  end

  def unwatch(name, pid) do
    cast(name, {:untap, pid})
  end

  def launch(name, opts \\ []) do
    cmd = get(opts, :cmd, "claude --dangerously-skip-permissions")
    {:ok, pid} = boot(name, cmd, finalize(opts, cmd))
    invoke(get(opts, :resize), pid)
    pid
  end

  def join(pid) do
    await(pid)
  end

  def run(name, opts \\ []) do
    launch(name, opts) |> join()
  end

  defp invoke(nil, _pid), do: :ok
  defp invoke(resizer, pid), do: resizer.(pid)

  defp hang(ref, pid) do
    receive do
      {:DOWN, ^ref, :process, ^pid, _} -> :ok
    end
  end

  defp await(pid) do
    hang(monitor(pid), pid)
  end

  @impl true
  def init({name, cmd, opts}) do
    {:ok, call(build(cmd, [name: name] ++ opts))}
  end

  @impl true
  def handle_info(msg, state) do
    info(msg, state)
  end

  @impl true
  def handle_call(msg, _from, state) do
    reply(msg, state)
  end

  @impl true
  def handle_cast(msg, state) do
    relay(msg, state)
  end
end
