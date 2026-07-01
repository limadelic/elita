defmodule Tape.Replay.Relaxed do
  import Jason
  import Enum, only: [find_index: 2, drop: 2]

  def matched_replay(entries, messages, agent_name, request_fun, body) do
    matcher = select_matcher()
    match_result = find_match(entries, messages, agent_name, matcher)
    use_match(match_result, agent_name, body, request_fun)
  end

  defp use_match({idx, response}, agent_name, _body, _request_fun) do
    consume(agent_name, idx)
    response
  end
  defp use_match(:not_found, agent_name, body, request_fun) do
    Tape.Store.record_and_append(body, agent_name, request_fun)
  end

  defp find_match(entries, messages, agent_name, matcher) do
    idx = consumed_count(agent_name)
    entries |> drop(idx) |> find_entry(idx, messages, agent_name, matcher)
  end

  defp find_entry(tail, idx, messages, agent_name, matcher) do
    find_index(tail, &match_entry(&1, messages, agent_name, matcher))
    |> entry_response(tail, idx)
  end

  defp entry_response(nil, _tail, _idx), do: :not_found
  defp entry_response(offset, tail, idx) do
    entry = Enum.at(tail, offset)
    {idx + offset, Enum.at(entry, 2)}
  end

  defp match_entry([agent, req_json, _], messages, agent_name, matcher) do
    req = Jason.decode!(req_json)
    matcher.(messages, agent_name, agent, req)
  end

  defp select_matcher do
    get_matcher_type(System.get_env("MATCHER"))
  end

  defp get_matcher_type("relaxed"), do: &match_relaxed/4
  defp get_matcher_type(_matcher), do: &match_exact/4

  defp match_exact(messages, _agent_name, _recorded_agent, recorded_messages),
    do: messages == recorded_messages
  defp match_relaxed(_messages, agent_name, recorded_agent, _recorded_messages),
    do: agent_name == recorded_agent

  defp consumed_count(agent_name) do
    key = :"tape_pos_#{agent_name}"
    Process.get(key, 0)
  end

  defp consume(agent_name, idx) do
    key = :"tape_pos_#{agent_name}"
    Process.put(key, idx + 1)
  end
end
