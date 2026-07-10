defmodule El.Pty.Dispatch do
  @moduledoc false
  import El.Trace
  import El.Pty.Handler
  import El.Pty.Cleanup
  import List
  import Enum
  import :os, only: [cmd: 1]

  def info({pty, {:data, data}}, state) do
    import El.Log, only: [write: 1]
    write("dispatch: received pty output, size=#{byte_size(data)}, first=#{inspect(String.slice(data, 0..30))}\n")
    process(pty, data, state)
    {:noreply, state}
  end

  def info({:stdin, data}, %{pty: pty, port: port, input: input} = state) do
    import El.Log, only: [write: 1]
    write("dispatch: received stdin, size=#{byte_size(data)}\n")
    record(data)
    transformed = input.(data)
    write("dispatch: input function returned #{inspect(transformed)}\n")
    write("handler: about to write to pty\n")
    write(port, pty, transformed)
    write("handler: write completed\n")
    {:noreply, state}
  rescue
    e ->
      import El.Log, only: [write: 1]
      write("dispatch: error in stdin handler: #{inspect(e)}\n")
      raise e
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

  def info({pty, {:exit_status, _}}, %{pty: pty} = state) do
    finish(state)
    {:stop, :normal, state}
  end

  def info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def info({:EXIT, _pid, reason}, %{os_pid: os_pid} = state) do
    slay(os_pid)
    {:stop, reason, state}
  end

  def info({pty, :closed}, %{pty: pty, os_pid: os_pid} = state) do
    slay(os_pid)
    {:stop, :normal, state}
  end

  def info(msg, state) do
    import El.Log, only: [write: 1]
    tag = if is_tuple(msg), do: elem(msg, 0), else: msg
    write("dispatch: unhandled message tag=#{inspect(tag)}\n")
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
