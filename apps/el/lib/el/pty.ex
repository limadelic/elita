defmodule El.Pty do
  @moduledoc false
  use GenServer

  import Keyword, except: [size: 1]
  import Process, except: [alias: 1, info: 2]

  import GenServer, only: [start_link: 3, cast: 2, call: 2]
  import El.Pty.Init, only: [call: 1]
  import El.Pty.Size, only: [get_default: 0]

  def boot(name, cmd, opts \\ []) do
    start_link(__MODULE__, {cmd, opts}, name: name)
  end

  def inject(name, message) do
    cast(name, {:inject, message})
  end

  def tap(name, pid) do
    call(name, {:tap, pid})
  end

  def untap(name, pid) do
    call(name, {:untap, pid})
  end

  def run(name, opts \\ []) do
    cmd = get(opts, :cmd, "claude --dangerously-skip-permissions")
    full_opts = build_options(opts, cmd)
    {:ok, pid} = boot(name, cmd, full_opts)
    wait_exit(pid)
  end

  defp build_options(opts, _cmd) do
    clean = opts |> drop([:input, :taps, :cmd])
    clean ++ defaults(opts)
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

  defp wait_exit(pid) do
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
  defp size(opts), do: get(opts, :get_size, &get_default/0)
  defp input(opts), do: get(opts, :input, fn x -> x end)
  defp taps(opts), do: get(opts, :taps, [])

  @impl true
  def handle_info(msg, state) do
    El.Pty.Dispatch.info(msg, state)
  end

  @impl true
  def handle_call(msg, _from, state) do
    El.Pty.Dispatch.call(msg, state)
  end

  @impl true
  def handle_cast(msg, state) do
    El.Pty.Dispatch.cast(msg, state)
  end
end
