defmodule Matrix.Pty.Dispatch do
  @moduledoc false
  import Matrix.Pty.Cleanup
  import Matrix.Pty.Buffer, only: [prime: 2, gate: 2]
  import List, only: [delete: 2]
  import IO, only: [binwrite: 2]
  import Matrix.Pty.Retry
  import Matrix.Pty.Respawn
  import Matrix.Pty.Relay

  def info({pty, {:data, data}}, state) do
    updated = prime(state, data)
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

  def info({pty, {:exit_status, _}}, %{pty: pty, child: child, taps: taps} = state) do
    slay(pty, child)
    death(taps, state)
  end

  def info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def info({:EXIT, _pid, reason}, %{pty: pty, child: child, taps: taps} = state) do
    slay(pty, child)
    exit(taps, state, reason)
  end

  def info({pty, :closed}, %{pty: pty, child: child, taps: taps} = state) do
    slay(pty, child)
    death(taps, state)
  end

  def info(:retry_pty, %{retry_state: retry_state} = state) when retry_state != nil do
    result = (try do attempt(state) rescue _ -> :error end)
    handle(result, state)
  end

  defp handle({:ok, new_state}, _state), do: {:noreply, new_state}
  defp handle(:error, state), do: requeue(state)

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

  defp death(taps, state) when taps != [], do: {:noreply, begin(state)}
  defp death(_taps, state), do: {:stop, :normal, state}

  defp exit(taps, state, _reason) when taps != [], do: {:noreply, begin(state)}
  defp exit(_taps, state, reason), do: {:stop, reason, state}

  defp begin(state) do
    s = schedule(self(), init())
    %{state | retry_state: s}
  end
end
