defmodule Meter do
  import Application, only: [get_env: 3]
  import Jason, only: [encode!: 1]
  import File, only: [write: 3]

  def spend(kind, usage) do
    log(record(kind, usage))
  end

  defp record(kind, usage),
    do: %{kind: kind, in: fetch(usage, "input_tokens"), out: fetch(usage, "output_tokens")}

  defp fetch(nil, _key), do: 0
  defp fetch(usage, key), do: Map.get(usage, key, 0)

  defp log(data) do
    write(get_env(:elita, :spend_log, "/tmp/elita_spend.jsonl"), encode!(data) <> "\n", [:append])
  end
end
