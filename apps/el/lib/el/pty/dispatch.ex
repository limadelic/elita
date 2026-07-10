defmodule El.Pty.Dispatch do
  @moduledoc false
  import El.Trace
  import El.Pty.Handler
  import El.Pty.Cleanup
  import List
  import Enum
  import :os, only: [cmd: 1]

  def info({pty, {:data, data}}, state) do
    process(pty, data, state)
    {:noreply, state}
  end

  def info({:stdin, data}, %{pty: pty, port: port, input: input} = state) do
    record(data)
    write(port, pty, input.(data))
    {:noreply, state}
  end

  def info(:exit_wrap, %{port: port, os_pid: os_pid} = state) do
    port.close(port)
    slay(os_pid)
    {:stop, :normal, state}
  end

  def info({:resize, size}, %{port: _port} = state) do
    resize(size)
    {:noreply, state}
  end

  def info({pty, {:exit_status, status}}, %{pty: pty} = state) do
    emit("pty_exit_status", inspect(status))
    finish(state)
    {:stop, :normal, state}
  end

  def info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def info({:EXIT, _pid, reason}, %{os_pid: os_pid} = state) do
    emit("linked_exit", inspect(reason))
    slay(os_pid)
    {:stop, reason, state}
  end

  def info({pty, :closed}, %{pty: pty, os_pid: os_pid} = state) do
    emit("pty_closed")
    slay(os_pid)
    {:stop, :normal, state}
  end

  def info(msg, state) do
    emit("unknown_info", inspect(msg))
    {:noreply, state}
  end

  def call({:tap, pid}, %{taps: taps} = state) do
    {:reply, :ok, %{state | taps: [pid | taps]}}
  end

  def call({:untap, pid}, %{taps: taps} = state) do
    {:reply, :ok, %{state | taps: delete(taps, pid)}}
  end

  def cast({:inject, msg}, %{pty: pty, port: port} = state) do
    record(msg)
    port.command(pty, msg)
    {:noreply, state}
  end

  defp broadcast(taps, data) do
    each(taps, fn pid -> send(pid, {:output, data}) end)
  end

  defp cleanup(os_pid, file, out) do
    slay(os_pid)
    file.close(out)
  end

  defp process(pty, data, %{port: port, file: file, out: out, taps: taps} = state) do
    file.write(out, data)
    broadcast(taps, data)
    respond(port, pty, data, state)
  end

  defp finish(%{os_pid: os_pid, file: file, out: out}) do
    cleanup(os_pid, file, out)
  end

  defp resize({rows, cols}) do
    "stty rows #{rows} cols #{cols} < /dev/tty" |> String.to_charlist() |> cmd()
  rescue
    _ -> :ok
  end
end
