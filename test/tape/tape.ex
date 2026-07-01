defmodule Tape do
  import System, only: [get_env: 1]
  import Jason
  import Enum, only: [find_index: 2, drop: 2]
  import Tape.Matcher, only: [contains: 2]
  alias Tape.Store

  def play(body, agent_name, request_fun) do
    if get_env("REC") == "1", do: Store.record(body, agent_name, request_fun), else: replay_or_record(body, agent_name, request_fun)
  end

  defp replay_or_record(body, agent_name, request_fun) do
    data = Store.read_cassette()
    messages = body[:messages] || []
    do_replay(data, messages, body, agent_name, request_fun)
  end

  defp do_replay({:old_format, map}, messages, body, agent_name, request_fun),
    do: old_replay(map, messages, body, agent_name, request_fun)
  defp do_replay({:new_format, entries}, messages, body, agent_name, request_fun),
    do: new_replay(entries, messages, body, agent_name, request_fun)

  defp old_replay(cassette_map, messages, body, agent_name, request_fun) do
    key = Store.content_key(messages)
    use_old(Map.fetch(cassette_map, key), body, agent_name, request_fun)
  end

  defp use_old({:ok, content}, _body, _agent_name, _request_fun), do: content
  defp use_old(:error, body, agent_name, request_fun), do: Store.record_and_append(body, agent_name, request_fun)

  defp new_replay([%{} | _] = entries, _messages, body, _agent_name, request_fun),
    do: first_match(entries, body, request_fun)
  defp new_replay([], _messages, body, _agent_name, request_fun),
    do: live(body, request_fun)
  defp new_replay(entries, messages, body, agent_name, request_fun),
    do: matched_replay(entries, messages, agent_name, request_fun, body)

  defp first_match(entries, body, request_fun) do
    incoming = normalize(request(body))
    find_match(entries, incoming, 0, body, request_fun)
  end

  defp find_match(entries, incoming, idx, body, request_fun) when idx < length(entries) do
    entry = Enum.at(entries, idx)
    if matches_and_available?(entry, incoming, idx), do: use_entry(entry, idx), else: find_match(entries, incoming, idx + 1, body, request_fun)
  end

  defp find_match(_entries, _incoming, _idx, body, request_fun), do: live(body, request_fun)

  defp use_entry(entry, idx) do
    increment_hit_count(idx)
    entry["res"]
  end

  defp matches_and_available?(entry, incoming, idx) do
    req = entry["req"]
    contains(req, incoming) and not exhausted?(entry, idx)
  end

  defp exhausted?(entry, idx) do
    times = entry["times"] || 1
    times != "always" and get_hit_count(idx) >= times
  end

  defp get_hit_count(idx) do
    key = :"tape_hit_#{cassette_key()}_#{idx}"
    Process.get(key, 0)
  end

  defp increment_hit_count(idx) do
    key = :"tape_hit_#{cassette_key()}_#{idx}"
    current = Process.get(key, 0)
    Process.put(key, current + 1)
  end

  defp cassette_key, do: get_env("CASSETTE")

  defp matched_replay(entries, messages, agent_name, request_fun, body) do
    matcher = select_matcher()
    match_result = find_match(entries, messages, agent_name, matcher)
    use_match(match_result, agent_name, body, request_fun)
  end

  defp use_match({idx, response}, agent_name, _body, _request_fun) do
    consume(agent_name, idx)
    response
  end
  defp use_match(:not_found, agent_name, body, request_fun) do
    Store.record_and_append(body, agent_name, request_fun)
  end

  defp normalize(req), do: req |> encode!() |> decode!()

  defp live(body, request_fun) do
    response = request_fun.()
    Store.append_live(request(body), response)
    response
  end

  defp request(body), do: Map.take(body, [:system, :messages, :tools])

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
    req = decode!(req_json)
    matcher.(messages, agent_name, agent, req)
  end

  defp select_matcher do
    case get_env("MATCHER") do
      "relaxed" -> &match_relaxed/4
      _ -> &match_exact/4
    end
  end

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
