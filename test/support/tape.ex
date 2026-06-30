defmodule Tape do
  import File, only: [write: 2, read!: 1, exists?: 1, mkdir_p: 1]
  import System, only: [get_env: 1]
  import Jason
  import Enum, only: [find_index: 2, drop: 2]

  def play(body, agent_name, request_fun) do
    if get_env("REC") == "1" do
      record(body, agent_name, request_fun)
    else
      replay_or_record(body, agent_name, request_fun)
    end
  end

  defp replay_or_record(body, agent_name, request_fun) do
    data = read_cassette_data()
    messages = body[:messages] || []
    case data do
      {:old_format, cassette_map} ->
        old_replay(cassette_map, messages, body, agent_name, request_fun)
      {:new_format, entries} ->
        new_replay(entries, messages, body, agent_name, request_fun)
    end
  end

  defp old_replay(cassette_map, messages, body, agent_name, request_fun) do
    key = content_key(messages)
    case Map.fetch(cassette_map, key) do
      {:ok, content} -> content
      :error -> record_and_append(body, agent_name, request_fun)
    end
  end

  defp new_replay(entries, messages, body, agent_name, request_fun) do
    matcher = select_matcher()
    case find_match(entries, messages, agent_name, matcher) do
      {idx, response} ->
        consume(agent_name, idx)
        response
      :not_found ->
        record_and_append(body, agent_name, request_fun)
    end
  end

  defp find_match(entries, messages, agent_name, matcher) do
    idx = consumed_count(agent_name)
    entries
    |> drop(idx)
    |> find_index(fn [agent, req_json, _] ->
      req = decode!(req_json)
      matcher.(messages, agent_name, agent, req)
    end)
    |> case do
      nil -> :not_found
      offset ->
        entry_idx = idx + offset
        [_, _, response] = Enum.at(entries, entry_idx)
        {entry_idx, response}
    end
  end

  defp record_and_append(body, agent_name, request_fun) do
    result = request_fun.()
    messages = body[:messages] || []
    
    case get_env("MATCHER") do
      "relaxed" ->
        append_new_entry(agent_name, messages, result)
      _ ->
        append_old_entry(messages, result)
    end
    result
  end

  defp record(body, agent_name, request_fun) do
    result = request_fun.()
    messages = body[:messages] || []
    
    case get_env("MATCHER") do
      "relaxed" ->
        write_new_entry(agent_name, messages, result)
      _ ->
        write_old_entry(messages, result)
    end
    result
  end

  defp append_new_entry(agent_name, messages, response) do
    path = cassette_file()
    mkdir_p(cassette_dir())
    entries =
      case read_cassette_data() do
        {:new_format, e} -> e
        _ -> []
      end
    req_json = encode!(messages)
    updated = entries ++ [[agent_name, req_json, response]]
    write(path, encode!(updated, pretty: true))
  end

  defp write_new_entry(agent_name, messages, response) do
    path = cassette_file()
    mkdir_p(cassette_dir())
    req_json = encode!(messages)
    updated = [[agent_name, req_json, response]]
    write(path, encode!(updated, pretty: true))
  end

  defp append_old_entry(messages, response) do
    path = cassette_file()
    mkdir_p(cassette_dir())
    cassette =
      case read_cassette_data() do
        {:old_format, c} -> c
        _ -> %{}
      end
    key = content_key(messages)
    updated = Map.put(cassette, key, response)
    write(path, encode!(updated))
  end

  defp write_old_entry(messages, response) do
    path = cassette_file()
    mkdir_p(cassette_dir())
    key = content_key(messages)
    updated = %{key => response}
    write(path, encode!(updated))
  end

  defp read_cassette_data do
    path = cassette_file()
    if exists?(path) do
      data = path |> read!() |> decode!()
      if is_map(data) do
        {:old_format, data}
      else
        {:new_format, data}
      end
    else
      {:old_format, %{}}
    end
  end

  defp content_key(messages) do
    :erlang.phash2(messages) |> to_string()
  end

  defp select_matcher do
    case get_env("MATCHER") do
      "relaxed" -> &match_relaxed/4
      _ -> &match_exact/4
    end
  end

  defp match_exact(messages, _agent_name, _recorded_agent, recorded_messages) do
    messages == recorded_messages
  end

  defp match_relaxed(_messages, agent_name, recorded_agent, _recorded_messages) do
    agent_name == recorded_agent
  end

  defp consumed_count(agent_name) do
    key = :"tape_pos_#{agent_name}"
    Process.get(key, 0)
  end

  defp consume(agent_name, idx) do
    key = :"tape_pos_#{agent_name}"
    Process.put(key, idx + 1)
  end

  defp cassette_file do
    "test/cassettes/#{get_env("CASSETTE")}.json"
  end

  defp cassette_dir do
    "test/cassettes"
  end
end
