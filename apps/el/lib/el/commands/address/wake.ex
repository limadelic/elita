defmodule El.Commands.Address.Wake do
  import Agent.Session, only: [start_link: 1]
  import Enum, only: [empty?: 1]
  import Map, only: [get: 2]
  import String, only: [downcase: 1, to_atom: 1]
  import System, only: [get_env: 1]
  import Code, only: [ensure_loaded?: 1]
  import Keyword, only: [put: 3]
  import Registry, only: [lookup: 2]

  def up(%{kind: k, name: n, path: p} = entry) when k in [:file, :folder] do
    key = n |> to_string() |> downcase()
    sleep = lookup(ElitaRegistry, key) |> empty?()
    go(sleep, n, p, get(entry, :file_path))
  end

  def up(_), do: :ok

  defp go(false, _name, _folder, _self), do: :ok

  defp go(true, name, folder, self) do
    rune = get_env("TEST_AGENT_RUNNER") |> runner()
    start_link(config([name: name, folder: folder, self: self], rune))
  end

  defp runner(nil), do: nil

  defp runner(name) do
    atom = to_atom("Elixir." <> name)
    load(ensure_loaded?(atom), atom)
  end

  defp load(true, a), do: a
  defp load(false, _), do: nil

  defp config(opts, nil), do: opts

  defp config(opts, rune),
    do: put(opts, :runner, fn m, f -> apply(rune, :run, [m, f]) end)
end
