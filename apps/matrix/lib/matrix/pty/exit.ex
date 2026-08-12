defmodule Matrix.Pty.Exit do
  @moduledoc false
  import Matrix.Pty.Cleanup
  import Matrix.Pty.Retry
  import Matrix.Movie.Seam, only: [done: 2]

  def handle({_pty, {:exit_status, _}}, state) do
    finish(state)
  end

  def handle({:EXIT, _pid, reason}, state) do
    wrap(state, reason)
  end

  def handle({_pty, :closed}, state) do
    finish(state)
  end

  defp finish(%{pty: pty, child: child, taps: taps, name: name, recorder: rec} = state) do
    slay(pty, child)
    done(rec, name)
    cease(taps, state)
  end

  defp wrap(%{pty: pty, child: child, taps: taps, name: name, recorder: rec} = state, reason) do
    slay(pty, child)
    done(rec, name)
    cease(taps, state, reason)
  end

  defp cease(taps, state) when taps != [], do: {:noreply, retry(state)}
  defp cease(_taps, state), do: {:stop, :normal, state}

  defp cease(taps, state, _reason) when taps != [], do: {:noreply, retry(state)}
  defp cease(_taps, state, reason), do: {:stop, reason, state}

  defp retry(state) do
    s = schedule(self(), init())
    %{state | retry_state: s}
  end
end
