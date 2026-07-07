defmodule El.Pty do
  @moduledoc false
  use GenServer

  alias El.Pty.Dispatch
  alias El.Pty.Init
  alias El.Pty.Size

  def start_link(name, cmd, opts \\ []) do
    GenServer.start_link(__MODULE__, {cmd, opts}, name: name)
  end

  def inject(name, message) do
    GenServer.cast(name, {:inject, message})
  end

  def tap(name, pid) do
    GenServer.call(name, {:tap, pid})
  end

  def untap(name, pid) do
    GenServer.call(name, {:untap, pid})
  end

  def run(name, opts \\ []) do
    cmd = Keyword.get(opts, :cmd, "claude --dangerously-skip-permissions")
    full_opts = build_options(opts, cmd)
    {:ok, pid} = start_link(name, cmd, full_opts)
    wait_exit(pid)
  end

  defp build_options(opts, _cmd) do
    clean = opts |> Keyword.drop([:input, :taps, :cmd])
    clean ++ defaults(opts)
  end

  defp defaults(opts) do
    [
      input: Keyword.get(opts, :input, fn x -> x end),
      taps: Keyword.get(opts, :taps, [])
    ]
  end

  defp wait_exit(pid) do
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, _} -> :ok
    end
  end

  @impl true
  def init({cmd, opts}) do
    {:ok, build(cmd, opts)}
  end

  defp build(cmd, opts) do
    Init.call(config(cmd, opts))
  end

  defp config(cmd, opts) do
    [file: file(opts), port: port(opts), cmd: cmd] ++
      [get_size: size(opts), input: input(opts), taps: taps(opts)]
  end

  defp file(opts), do: Keyword.get(opts, :file, :file)
  defp port(opts), do: Keyword.get(opts, :port, Port)
  defp size(opts), do: Keyword.get(opts, :get_size, &Size.get_default/0)
  defp input(opts), do: Keyword.get(opts, :input, fn x -> x end)
  defp taps(opts), do: Keyword.get(opts, :taps, [])

  @impl true
  def handle_info(msg, state) do
    Dispatch.info(msg, state)
  end

  @impl true
  def handle_call(msg, _from, state) do
    Dispatch.call(msg, state)
  end

  @impl true
  def handle_cast(msg, state) do
    Dispatch.cast(msg, state)
  end
end
