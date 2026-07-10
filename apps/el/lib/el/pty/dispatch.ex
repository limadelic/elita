defmodule El.Pty.Dispatch do
  @moduledoc false
  import El.Trace
  import El.Pty.Handler
  import El.Pty.Cleanup
  import List, only: [delete: 2]
  import Enum, only: [each: 2]
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

  def info(:exit_wrap, %{port: port, child: child} = state) do
    port.close(port)
    slay(child)
    {:stop, :normal, state}
  end

  def info({:resize, size}, %{port: _port} = state) do
    resize(size)
    {:noreply, state}
  end

  def info({pty, {:exit_status, _}}, %{pty: pty} = state) do
    finish(state)
    {:stop, :normal, state}
  end

  def info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def info({:EXIT, _pid, reason}, %{child: child} = state) do
    slay(child)
    {:stop, reason, state}
  end

  def info({pty, :closed}, %{pty: pty, child: child} = state) do
    slay(child)
    {:stop, :normal, state}
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

  defp cleanup(child, file, out) do
    slay(child)
    file.close(out)
  end

  defp process(pty, data, %{port: port, file: file, out: out, taps: taps} = state) do
    file.write(out, data)
    broadcast(taps, data)
    respond(port, pty, data, state)
  end

  defp finish(%{child: child, file: file, out: out}) do
    cleanup(child, file, out)
  end

  defp resize({rows, cols}) do
    "stty rows #{rows} cols #{cols} < /dev/tty" |> to_charlist() |> cmd()
  rescue
    _ -> :ok
  end
end
