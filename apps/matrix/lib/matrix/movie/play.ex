defmodule Matrix.Movie.Play do
  @moduledoc false
  import Matrix.Movie.Load, only: [run: 1]
  import Enum, only: [each: 2]

  def open(name, opts) do
    handle = make_ref()
    recipient = pick(opts)
    spawn(fn -> deliver(handle, name, recipient) end)
    handle
  end

  defp pick(opts) when is_list(opts), do: pick(opts[:recipient])
  defp pick(r) when is_pid(r), do: r
  defp pick(_), do: self()

  defp deliver(handle, name, recipient) do
    run(name)
    |> each(&post(handle, recipient, &1))
    |> then(fn _ -> send(recipient, {handle, :closed}) end)
  end

  defp post(handle, recipient, chunk) do
    send(recipient, {handle, {:data, chunk}})
  end

  def command(_handle, _data) do
    :ok
  end

  def close(_handle) do
    :ok
  end

  def info(_handle, :os_pid) do
    {:os_pid, 1}
  end

  def info(_handle, _key) do
    nil
  end
end
