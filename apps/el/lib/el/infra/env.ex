defmodule El.Infra.Env do
  import System, only: [get_env: 0, get_env: 1]

  def get, do: get_env()

  def get(name), do: get_env(name)

  def get(name, default) do
    resolve(get_env(name), default)
  end

  defp resolve(nil, default), do: default
  defp resolve(value, _), do: value
end
