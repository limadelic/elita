defmodule El.Commands.Address.Wake do
  import Agent.Session, only: [start_link: 1]

  def up(%{kind: k, name: n, path: p} = entry) when k in [:file, :folder] do
    key = n |> to_string() |> String.downcase()
    sleep = Registry.lookup(ElitaRegistry, key) |> Enum.empty?()
    go(sleep, n, p, Map.get(entry, :file_path))
  end

  def up(_), do: :ok

  defp go(false, _name, _folder, _self), do: :ok

  defp go(true, name, folder, self) do
    rune = System.get_env("TEST_AGENT_RUNNER") |> runner()
    start_link(config([name: name, folder: folder, self: self], rune))
  end

  defp runner(nil), do: nil

  defp runner(name) do
    atom = String.to_atom("Elixir." <> name)
    load(Code.ensure_loaded?(atom), atom)
  end

  defp load(true, a), do: a
  defp load(false, _), do: nil

  defp config(opts, nil), do: opts

  defp config(opts, rune),
    do: Keyword.put(opts, :runner, fn m, f -> apply(rune, :run, [m, f]) end)
end
