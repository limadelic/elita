defmodule Matrix.Pty.Dispatch do
  @moduledoc false
  import Matrix.Pty.Cleanup
  import Matrix.Pty.Buffer, only: [prime: 2, gate: 2]
  import List, only: [delete: 2]
  import IO, only: [binwrite: 2]
  import Matrix.Pty.Respawn
  import Matrix.Pty.Relay
  import Matrix.Movie.Seam, only: [save: 2]
  import Matrix.Pty.Exit, only: [handle: 2]

  def info({pty, {:data, data}}, state) do
    updated = prime(state, data)
    save(state.recorder, data)
    data(pty, data, updated)
    {:noreply, updated}
  end

  def info({:stdin, data}, %{pty: pty, port: port, input: input} = state) do
    stdin(port, pty, input, data)
    {:noreply, state}
  end

  def info(:exit_wrap, %{pty: pty, port: port, child: child} = state) do
    port.close(port)
    slay(pty, child)
    {:stop, :normal, state}
  end

  def info({:prompt, agent}, %{out: out} = state) do
    binwrite(out, "#{agent}> ")
    {:noreply, state}
  end

  def info({:resize, size}, %{port: _port} = state) do
    terminal(size)
    {:noreply, state}
  end

  def info({_pty, {:exit_status, _}} = msg, state) do
    handle(msg, state)
  end

  def info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def info({:EXIT, _pid, _reason} = msg, state) do
    handle(msg, state)
  end

  def info({_pty, :closed} = msg, state) do
    handle(msg, state)
  end

  def info(:retry_pty, %{retry_state: retry_state} = state) when retry_state != nil do
    revive(state)
  end

  defp revive(state) do
    attempt(state)
  rescue
    _ -> requeue(state)
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
    {:noreply, gate(msg, state)}
  end

  def cast({:inject, msg}, state) do
    {:noreply, gate(msg, state)}
  end
end
