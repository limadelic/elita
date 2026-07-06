defmodule El.Infra.Env do
  def get, do: System.get_env()

  def get(name), do: System.get_env(name)
end
