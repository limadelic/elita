defmodule Matrix.Pty.Respawn do
  @moduledoc false
  import Matrix.Pty.Boot, only: [launch: 3]
  import Matrix.Pty.Watch, only: [start: 1]
  import Matrix.Pty.Retry

  def attempt(state) do
    {:ok, s} = open(state)
    {:noreply, s}
  end

  def requeue(%{retry_state: state} = s) do
    limit(next(state), s)
  end

  defp limit(state, s) when state.total > 60_000, do: stop(s)

  defp limit(state, s) do
    {:noreply, %{s | retry_state: fire(self(), state)}}
  end

  defp open(state) do
    %{port: port, cmd: cmd, get_size: size_fn} = state
    pty = launch(port, cmd, size_fn.())
    start(pty)
    {:ok, %{state | pty: pty, child: pid(port.info(pty, :os_pid)), retry_state: nil}}
  end

  defp pid({:os_pid, id}), do: id
  defp pid(_), do: nil

  defp stop(state), do: {:stop, :pty_retry_exhausted, state}
end
