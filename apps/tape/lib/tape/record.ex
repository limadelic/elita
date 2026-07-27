defmodule Tape.Record do
  import Tape.Store, only: [add: 4]
  import System, only: [get_env: 1]
  import Map, only: [get: 3]
  import List, only: [last: 1]

  def record(body, name, fun) do
    response = fun.()
    add(get_env("CASSETTE"), get_env("CASSETTE_DIR"), sparse(body, name), response)
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
