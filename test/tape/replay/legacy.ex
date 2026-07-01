defmodule Tape.Replay.Legacy do
  alias Tape.Store

  def old_replay(cassette_map, messages, body, agent_name, request_fun) do
    key = Store.content_key(messages)
    use_old(Map.fetch(cassette_map, key), body, agent_name, request_fun)
  end

  defp use_old({:ok, content}, _body, _agent_name, _request_fun), do: content
  defp use_old(:error, body, agent_name, request_fun), do: Store.record_and_append(body, agent_name, request_fun)
end
