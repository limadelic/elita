defmodule El.Host do
  @moduledoc false
  import Keyword, only: [get: 3]
  import String, only: [contains?: 2]

  def host(opts \\ []) do
    env_module = get(opts, :env_module, El.Infra.Env)
    env_module.get("EL_HOST") |> default_host()
  end

  defp default_host(nil), do: "127.0.0.1"
  defp default_host(h), do: h

  def naming_mode(h) do
    pick_naming_mode(contains?(h, "."))
  end

  defp pick_naming_mode(true), do: :longnames
  defp pick_naming_mode(false), do: :shortnames
end
