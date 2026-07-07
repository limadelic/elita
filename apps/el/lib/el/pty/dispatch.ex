defmodule El.Pty.Dispatch do
  @moduledoc false
  import El.Trace

  alias El.Pty.Cleanup
  alias El.Pty.Handler

  def info({pty, {:data, data}}, state) do
    %{port: port, file: file, tty_out: tty_out, taps: taps} = state
    file.write(tty_out, data)
    broadcast(taps, data)
    Handler.handle_dsr_response(port, pty, data, state)
    {:noreply, state}
  end

  def info({:stdin, data}, %{pty: pty, port: port, input: input} = state) do
    log_chunk(data)
    Handler.process_input(port, pty, input.(data))
    {:noreply, state}
  end

  def info(
        {pty, {:exit_status, _}},
        %{pty: pty, file: file, tty_out: tty_out, os_pid: os_pid} = state
      ) do
    close_stream(os_pid, file, tty_out)
    {:stop, :normal, state}
  end

  def info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def info({:EXIT, _pid, reason}, %{os_pid: os_pid} = state) do
    Cleanup.kill_group(os_pid)
    {:stop, reason, state}
  end

  def info({pty, :closed}, %{pty: pty, os_pid: os_pid} = state) do
    Cleanup.kill_group(os_pid)
    {:stop, :normal, state}
  end

  def call({:tap, pid}, %{taps: taps} = state) do
    {:reply, :ok, %{state | taps: [pid | taps]}}
  end

  def call({:untap, pid}, %{taps: taps} = state) do
    {:reply, :ok, %{state | taps: List.delete(taps, pid)}}
  end

  def cast({:inject, msg}, %{pty: pty, port: port} = state) do
    log_chunk(msg)
    port.command(pty, msg)
    {:noreply, state}
  end

  defp broadcast(taps, data) do
    Enum.each(taps, fn pid -> send(pid, {:output, data}) end)
  end

  defp close_stream(os_pid, file, tty_out) do
    Cleanup.kill_group(os_pid)
    file.close(tty_out)
  end
end
