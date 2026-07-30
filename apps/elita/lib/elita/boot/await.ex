defmodule Elita.Boot.Await do
  import Elita.Boot.Announce, only: [notify: 2]
  import Utils.Normalize, only: [name: 1]

  def handle({:ok, pid}, n), do: pin(pid, n)
  def handle({:error, {:already_started, pid}}, n), do: pin(pid, n)
  def handle({:error, {:shutdown, wrapped}}, n), do: unwrap(wrapped, n)

  def handle({:error, :duplicate}, n) do
    :global.whereis_name({name(n), :puppet}) |> bond(n)
  end

  def handle(other, _n), do: other

  defp pin(pid, n) do
    notify(n, pid)
    {:ok, pid}
  end

  defp bond(:undefined, _n), do: {:error, :attach_failed}

  defp bond(p, n) do
    notify(n, p)
    {:ok, p}
  end

  defp unwrap({:failed_to_start_child, :session, :duplicate}, n),
    do: handle({:error, :duplicate}, n)

  defp unwrap({:failed_to_start_child, :session, {:already_started, pid}}, n),
    do: handle({:error, {:already_started, pid}}, n)

  defp unwrap(other, _n), do: {:error, {:shutdown, other}}
end
