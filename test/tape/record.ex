defmodule Tape.Record do
  alias Tape.Store

  def handle(body, name, fun) do
    response = fun.()
    Store.append_live(sparse(body, name), response)
    response
  end

  defp sparse(body, name) do
    messages = Map.get(body, :messages, [])
    %{"agent" => name, "messages" => last_only(messages)}
  end

  defp last_only([]), do: []
  defp last_only(messages), do: [List.last(messages)]
end
