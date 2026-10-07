defmodule Freeq.Keys do
  import File, only: [read: 1, write: 2, mkdir_p: 1, chmod: 2]
  import System, only: [get_env: 2]
  import Path, only: [expand: 1, join: 2]

  def seed(name) do
    path = join(root(), "#{name}.key")
    mkdir_p(root())
    read(path) |> pick(path)
  end

  def cert(name) do
    read(join(root(), name <> ".cert"))
  end

  defp root do
    get_env("ELITA_KEYS", expand("~/.elita/keys"))
  end

  defp pick({:ok, bytes}, _path), do: {:ok, bytes}

  defp pick({:error, :enoent}, path) do
    bytes = :crypto.strong_rand_bytes(32)
    write(path, bytes)
    chmod(path, 0o600)
    {:ok, bytes}
  end
end
