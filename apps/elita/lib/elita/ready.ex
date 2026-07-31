defmodule Elita.Ready do
  import :ets, only: [insert: 2, lookup: 2, whereis: 1]

  def up, do: insert(:elita_vault, {:ready, true})

  def ready?, do: check(whereis(:elita_vault))

  defp check(:undefined), do: false

  defp check(_), do: lookup(:elita_vault, :ready) == [ready: true]
end
