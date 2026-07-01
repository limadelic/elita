defmodule Tape.Store do
  import File, only: [write: 2, read!: 1, exists?: 1, mkdir_p: 1]
  import System, only: [get_env: 1]
  import Jason

  def read_cassette do
    path = cassette_file()
    if exists?(path), do: parse_cassette(read!(path)), else: {:old_format, %{}}
  end

  def load_entries do
    case read_cassette(), do: ({:new_format, e} -> e; _ -> [])
  end

  def load_old_entries do
    case read_cassette(), do: ({:old_format, c} -> c; _ -> %{})
  end

  def append_live(req, response) do
    entries = load_entries()
    path = cassette_file()
    mkdir_p(cassette_dir())
    write(path, encode!(entries ++ [%{"req" => req, "res" => response}], pretty: true))
  end

  def record_and_append(body, agent_name, request_fun) do
    result = request_fun.()
    messages = body[:messages] || []
    save_append(agent_name, messages, result)
    result
  end

  def record(body, agent_name, request_fun) do
    result = request_fun.()
    messages = body[:messages] || []
    save_record(agent_name, messages, result)
    result
  end

  def save_append(agent_name, messages, response) do
    case get_env("MATCHER") do
      "relaxed" -> append_new_entry(agent_name, messages, response)
      _ -> append_old_entry(messages, response)
    end
  end

  def save_record(agent_name, messages, response) do
    case get_env("MATCHER") do
      "relaxed" -> write_new_entry(agent_name, messages, response)
      _ -> write_old_entry(messages, response)
    end
  end

  def content_key(messages) do
    :erlang.phash2(messages) |> to_string()
  end

  defp append_new_entry(agent_name, messages, response) do
    entries = load_entries()
    save_entries(entries ++ [[agent_name, encode!(messages), response]], true)
  end

  defp write_new_entry(agent_name, messages, response) do
    save_entries([[agent_name, encode!(messages), response]], true)
  end

  defp append_old_entry(messages, response) do
    cassette = load_old_entries()
    key = content_key(messages)
    save_old_entries(Map.put(cassette, key, response))
  end

  defp write_old_entry(messages, response) do
    key = content_key(messages)
    save_old_entries(%{key => response})
  end

  defp save_entries(data, pretty) do
    mkdir_p(cassette_dir())
    write(cassette_file(), encode!(data, pretty: pretty))
  end

  defp save_old_entries(data) do
    mkdir_p(cassette_dir())
    write(cassette_file(), encode!(data))
  end

  defp parse_cassette(raw) do
    data = decode!(raw)
    if is_map(data), do: {:old_format, data}, else: {:new_format, data}
  end

  defp cassette_file do
    "test/cassettes/#{get_env("CASSETTE")}.json"
  end

  defp cassette_dir do
    "test/cassettes"
  end
end
