defmodule El.Standpoint do
  import Agent
  import File
  import Path

  def set(path) do
    expanded = expand(path)
    ensure()
    update(:standpoint, fn _old -> expanded end)
    :ok
  end

  def get do
    ensure()
    get(:standpoint, & &1)
  rescue
    _ -> birth()
  end

  def birth do
    cwd!() |> trim()
  end

  defp ensure do
    start_link(fn -> birth() end, name: :standpoint)
  rescue
    _ -> :ok
  end

  defp trim("/private" <> rest), do: rest
  defp trim(path), do: path
end
