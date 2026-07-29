defmodule Elita.Enlist do
  import Utils.Normalize, only: [name: 1]

  def handle(key, opts, name, configs) do
    :global.register_name(key, self())
    |> proceed(opts, name, configs)
  end

  defp proceed(:yes, opts, name, configs) do
    {:ok, opts, name, configs}
  end

  defp proceed(:no, _opts, _name, _configs) do
    {:stop, :duplicate}
  end

  def cleanup(state) do
    key = {name(state.name), :puppet}
    :global.whereis_name(key) |> sweep(key)
    forget(state.name)
  end

  def release(state) do
    key = {name(state.name), :puppet}
    :global.whereis_name(key) |> sweep(key)
  end

  defp sweep(pid, key) when pid == self(), do: :global.unregister_name(key)
  defp sweep(_pid, _key), do: :ok

  defp forget(name) do
    :ets.delete(:elita_vault, name)
  end
end
