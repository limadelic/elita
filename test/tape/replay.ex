defmodule Tape.Replay do
  import Jason
  alias Tape.Store
  alias Tape.Replay.Legacy
  alias Tape.Replay.Exact
  alias Tape.Replay.Relaxed

  def replay_or_record(body, agent_name, request_fun) do
    data = Store.read_cassette()
    messages = get_messages(body)
    do_replay(data, messages, body, agent_name, request_fun)
  end

  defp get_messages(%{messages: msgs}), do: msgs
  defp get_messages(_body), do: []

  defp do_replay({:old_format, map}, messages, body, agent_name, request_fun),
    do: Legacy.old_replay(map, messages, body, agent_name, request_fun)
  defp do_replay({:new_format, entries}, messages, body, agent_name, request_fun),
    do: new_replay(entries, messages, body, agent_name, request_fun)

  defp new_replay([%{} | _] = entries, _messages, body, _agent_name, request_fun),
    do: Exact.first_match(entries, body, request_fun)
  defp new_replay([], _messages, body, _agent_name, request_fun),
    do: live(body, request_fun)
  defp new_replay(entries, messages, body, agent_name, request_fun),
    do: Relaxed.matched_replay(entries, messages, agent_name, request_fun, body)

  def live(body, request_fun) do
    response = request_fun.()
    Store.append_live(request(body), response)
    response
  end

  defp request(body), do: Map.take(body, [:system, :messages, :tools])
end
