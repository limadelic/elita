defmodule Tape.Record do
  import Tape.Store, only: [append_live: 2]
  import Map, only: [get: 3]
  import List, only: [last: 1]

  def record(body, name, fun) do
    response = fun.()
    append_live(sparse(body, name), response)
    response
  end

  defp sparse(body, name) do
    messages = get(body, :messages, [])
    build(name, messages)
  end

  defp build(name, messages) do
    %{"agent" => name, "messages" => last_only(messages), "n" => length(messages)}
  end

  defp last_only([]), do: []
  defp last_only(messages), do: [last(messages)]
end
