defmodule Tape.Store do
  import File, only: [write: 2, read!: 1, exists?: 1, mkdir_p: 1]
  import System, only: [get_env: 1]
  import Jason
  alias Tape.Store.Entry

  def read_cassette do
    path = cassette_file()
    read_cassette_at(path, exists?(path))
  end

  defp read_cassette_at(path, true), do: parse_cassette(read!(path))
  defp read_cassette_at(_path, false), do: {:old_format, %{}}

  def load_entries do
    load_entries_from(read_cassette())
  end

  defp load_entries_from({:new_format, e}), do: e
  defp load_entries_from(_), do: []

  def load_old_entries do
    load_old_entries_from(read_cassette())
  end

  defp load_old_entries_from({:old_format, c}), do: c
  defp load_old_entries_from(_), do: %{}

  def append_live(req, response) do
    entries = load_entries()
    path = cassette_file()
    mkdir_p(cassette_dir())
    write(path, encode!(entries ++ [%{"q" => req, "a" => response}], pretty: true))
  end

  def record_and_append(body, agent_name, request_fun) do
    result = request_fun.()
    messages = get_messages(body)
    save_append(agent_name, messages, result)
    result
  end

  def record(body, agent_name, request_fun) do
    result = request_fun.()
    messages = get_messages(body)
    save_record(agent_name, messages, result)
    result
  end

  defp get_messages(%{messages: msgs}), do: msgs
  defp get_messages(_body), do: []

  def save_append(agent_name, messages, response) do
    save_append_via(get_env("MATCHER"), agent_name, messages, response)
  end

  defp save_append_via("relaxed", agent_name, messages, response),
    do: Entry.append_new_entry(agent_name, messages, response)
  defp save_append_via(_matcher, messages, response),
    do: Entry.append_old_entry(messages, response)

  def save_record(agent_name, messages, response) do
    save_record_via(get_env("MATCHER"), agent_name, messages, response)
  end

  defp save_record_via("relaxed", agent_name, messages, response),
    do: Entry.write_new_entry(agent_name, messages, response)
  defp save_record_via(_matcher, messages, response),
    do: Entry.write_old_entry(messages, response)

  def content_key(messages) do
    :erlang.phash2(messages) |> to_string()
  end

  defp parse_cassette(raw) do
    data = decode!(raw)
    parse_cassette_type(data)
  end

  defp parse_cassette_type(data) when is_map(data), do: {:old_format, data}
  defp parse_cassette_type(data), do: {:new_format, data}

  defp cassette_file do
    "test/cassettes/#{get_env("CASSETTE")}.json"
  end

  defp cassette_dir do
    "test/cassettes"
  end
end
