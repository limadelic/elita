defmodule El.Pty do
  @moduledoc false
  use GenServer

  import Keyword, only: [get: 2, get: 3]
  import Process, except: [alias: 1, info: 2, get: 2, get: 3]

  import El.Pty.Init, only: [call: 1]
  import El.Pty.Config, only: [build: 2, finalize: 2]
  import El.Pty.Dispatch, only: [info: 2]
  import GenServer, only: [start_link: 3, call: 2, cast: 2]

  def boot(name, cmd, opts \\ []) do
    start_link(__MODULE__, {cmd, opts}, name: name)
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

  def wait(pid) do
    await(pid)
  end

  def run(name, opts \\ []) do
    launch(name, opts) |> wait()
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
  def init({cmd, opts}) do
    {:ok, call(build(cmd, opts))}
  end

  @impl true
  def handle_info(msg, state) do
    info(msg, state)
  end

  @impl true
  def handle_call(msg, _from, state) do
    call(msg, state)
  end

  @impl true
  def handle_cast(msg, state) do
    cast(msg, state)
  end
end
