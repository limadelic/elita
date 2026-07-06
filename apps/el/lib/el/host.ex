defmodule El.Host do
  def host(opts \\ []) do
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)
    env_module.get("EL_HOST") || "127.0.0.1"
  end

  def naming_mode(h) do
    if String.contains?(h, "."), do: :longnames, else: :shortnames
  end
end
