defmodule Matrix.Pty.Cleanup do
  @moduledoc false

  def slay(nil, _), do: :ok
  def slay(pty, _), do: await(pty)

  defp await(pty) do
    ref = :erlang.monitor(:port, pty)
    grace(ref, pty)
  rescue
    _ -> :ok
  end

  defp grace(ref, pty) do
    receive do
      {:DOWN, ^ref, :port, ^pty, _} -> :ok
    after
      8_000 -> :ok
    end
  end
end
