defmodule Tape.Record do
  alias Tape.Store

  def handle(body, _name, fun) do
    response = fun.()
    Store.append_live(sparse(body), response)
    response
  end

  defp sparse(body) do
    messages = Map.get(body, :messages, [])
    %{messages: last_only(messages)}
  end

  defp last_only([]), do: []
  defp last_only(messages), do: [List.last(messages)]
end
