defmodule Tape.Record do
  import Tape.Store, only: [add: 2]
  import Map, only: [get: 3]
  import List, only: [last: 1]

  def record(body, name, fun) do
    response = fun.()
    add(sparse(body, name), response)
    response
  end

  defp sparse(body, name) do
    messages = get(body, :messages, [])
    build(name, messages)
  end

  defp build(name, messages) do
    %{"agent" => name, "messages" => recent(messages), "n" => length(messages)}
  end

  defp recent([]), do: []
  defp recent(messages), do: [last(messages)]
end
