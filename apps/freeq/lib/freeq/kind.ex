defmodule Freeq.Kind do
  @behaviour Agent.Kind
  import String, only: [split: 3, to_atom: 1]
  import Freeq, only: [tell: 3]

  @impl true
  def ask(_entry, _recipient, _message) do
    raise "ask through freeq is not supported"
  end

  @impl true
  def forward(_entry, recipient, message) do
    {sender, body} = decode(message)
    bridge = "freeq_#{sender}" |> to_atom()
    tell(bridge, recipient, body)
  end

  defp decode(message) do
    split(message, "[from ", parts: 2) |> process(message)
  end

  defp process([_prefix, rest], _message) do
    split(rest, "] ", parts: 2) |> extract()
  end

  defp process(_rest, message) do
    {"unknown", message}
  end

  defp extract([sender, body]), do: {sender, body}
  defp extract(_), do: {"unknown", ""}
end
