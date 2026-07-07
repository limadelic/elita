defmodule El.Standpoint do
  def set(path) do
    expanded = Path.expand(path)
    start_if_needed()
    Agent.update(:standpoint, fn _old -> expanded end)
    :ok
  end

  def get do
    start_if_needed()
    Agent.get(:standpoint, & &1)
  rescue
    _ -> birth()
  end

  def birth do
    File.cwd!() |> trim()
  end

  defp start_if_needed do
    Agent.start_link(fn -> birth() end, name: :standpoint)
  rescue
    _ -> :ok
  end

  defp trim("/private" <> rest), do: rest
  defp trim(path), do: path
end
