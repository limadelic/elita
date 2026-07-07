defmodule El.Pty do
  @moduledoc false
  use GenServer

  import El.Trace

  alias El.Pty.Cleanup
  alias El.Pty.Handler
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
    clean =
      opts
      |> Keyword.drop([:input, :taps, :cmd])

    clean ++
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
    {:ok,
     Init.call(
       file: Keyword.get(opts, :file, :file),
       port: Keyword.get(opts, :port, Port),
       cmd: cmd,
       get_size: Keyword.get(opts, :get_size, &Size.get_default/0),
       input: Keyword.get(opts, :input, fn x -> x end),
       taps: Keyword.get(opts, :taps, [])
     )}
  end

  @impl true
  def handle_info(
        {pty, {:data, data}},
        %{pty: pty, port: port, file: file, tty_out: tty_out, taps: taps} =
          state
      ) do
    file.write(tty_out, data)
    Enum.each(taps, fn pid -> send(pid, {:output, data}) end)
    Handler.handle_dsr_response(port, pty, data, state)
    {:noreply, state}
  end

  def handle_info({:stdin, data}, %{pty: pty, port: port, input: input} = state) do
    log_chunk(data)
    Handler.process_input(port, pty, input.(data))
    {:noreply, state}
  end

  def handle_info(
        {pty, {:exit_status, _}},
        %{pty: pty, file: file, tty_out: tty_out, os_pid: os_pid} = state
      ) do
    Cleanup.kill_group(os_pid)
    file.close(tty_out)
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, reason}, %{os_pid: os_pid} = state) do
    Cleanup.kill_group(os_pid)
    {:stop, reason, state}
  end

  def handle_info({pty, :closed}, %{pty: pty, os_pid: os_pid} = state) do
    Cleanup.kill_group(os_pid)
    {:stop, :normal, state}
  end

  @impl true
  def handle_call({:tap, pid}, _from, %{taps: taps} = state) do
    {:reply, :ok, %{state | taps: [pid | taps]}}
  end

  def handle_call({:untap, pid}, _from, %{taps: taps} = state) do
    {:reply, :ok, %{state | taps: List.delete(taps, pid)}}
  end

  @impl true
  def handle_cast({:inject, msg}, %{pty: pty, port: port} = state) do
    log_chunk(msg)
    port.command(pty, msg)
    {:noreply, state}
  end
end
