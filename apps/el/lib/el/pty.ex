defmodule El.Pty do
  @moduledoc false
  use GenServer

  import Keyword, only: [drop: 2, get: 2, get: 3]
  import Process, except: [alias: 1, info: 2, get: 2, get: 3]

  import El.Pty.Init, only: [call: 1]
  import El.Pty.Size, only: [default: 0]
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

  defp finalize(opts, _cmd) do
    drop(opts, [:input, :taps, :cmd, :resize]) ++ defaults(opts)
  end

  defp defaults(opts) do
    [
      input: get(opts, :input, fn x -> x end),
      taps: get(opts, :taps, [])
    ]
  end

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
    {:ok, build(cmd, opts)}
  end

  defp build(cmd, opts) do
    call(config(cmd, opts))
  end

  defp config(cmd, opts) do
    [file: file(opts), port: port(opts), cmd: cmd] ++
      [get_size: size(opts), input: input(opts), taps: taps(opts)]
  end

  defp file(opts), do: get(opts, :file, :file)
  defp port(opts), do: get(opts, :port, Port)
  defp size(opts), do: get(opts, :get_size, &default/0)
  defp input(opts), do: get(opts, :input, fn x -> x end)
  defp taps(opts), do: get(opts, :taps, [])

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
