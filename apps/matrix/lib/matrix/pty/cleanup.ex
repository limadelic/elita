defmodule Matrix.Pty.Cleanup do
  @moduledoc false

  import System, only: [cmd: 2]

  def slay(nil, _), do: :ok
  def slay(pty, nil), do: await(pty)

  def slay(pty, child) do
    strike(pty, child)
  rescue
    _ -> :ok
  end

  defp strike(pty, child) do
    signal(child, "-TERM")
    await(pty)
    signal(child, "-9")
  end

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

  defp signal(child, sig) do
    cmd("kill", [sig, "-#{child}"])
  rescue
    _ -> :ok
  end
end
