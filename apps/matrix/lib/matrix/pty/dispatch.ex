defmodule Matrix.Pty.Dispatch do
  @moduledoc false
  import Matrix.Trace
  import Matrix.Pty.Handler
  import Matrix.Pty.Cleanup
  import Matrix.Pty.Buffer, only: [prime: 2, gate: 2]
  import Matrix.Pty.Notify, only: [notify: 2]
  import Matrix.Pty.Log, only: [dump: 2]
  import List, only: [delete: 2]
  import :os, only: [cmd: 1]
  import Matrix.Log, only: [write: 1]
  import IO, only: [binwrite: 2]

  def info({pty, {:data, data}}, state) do
    write("PTY CHUNK #{byte_size(data)}b idle=#{state.idle}\n")
    updated = prime(state, data)
    process(pty, data, updated)
    {:noreply, updated}
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

  def info({:prompt, agent}, %{out: out} = state) do
    binwrite(out, "#{agent}> ")
    {:noreply, state}
  end

  def info({:resize, size}, %{port: _port} = state) do
    resize(size)
    {:noreply, state}
  end

  def info({pty, {:exit_status, _}}, %{pty: pty} = state) do
    slay(state.child)
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

  def cast({:untap, pid}, %{taps: taps} = state) do
    {:noreply, %{state | taps: delete(taps, pid)}}
  end

  def cast({:inject, msg, _reply}, state) do
    write("INJECT CAST RECEIVED reply #{byte_size(msg)}b\n")
    {:noreply, gate(msg, state)}
  end

  def cast({:inject, msg}, state) do
    write("INJECT CAST RECEIVED plain #{byte_size(msg)}b\n")
    {:noreply, gate(msg, state)}
  end

  defp process(pty, data, %{port: port, out: out, raw: raw, taps: taps} = state) do
    binwrite(out, data)
    dump(raw, data)
    notify(taps, data)
    respond(port, pty, data, state)
  end

  defp resize({rows, cols}) do
    "stty rows #{rows} cols #{cols} < /dev/tty" |> to_charlist() |> cmd()
  rescue
    _ ->
      :ok
  end
end
