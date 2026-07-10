defmodule El.Host do
  @moduledoc false
  import Keyword, only: [get: 3]
  import String, only: [contains?: 2]

  def host(opts \\ []) do
    env_module = get(opts, :env_module, El.Infra.Env)
    env_module.get("EL_HOST") |> fallback()
  end

  defp fallback(nil), do: "127.0.0.1"
  defp fallback(h), do: h

  def mode(h) do
    scheme(contains?(h, "."))
  end

  defp scheme(true), do: :longnames
  defp scheme(false), do: :shortnames
end
