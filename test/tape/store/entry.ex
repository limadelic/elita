defmodule Tape.Store.Entry do
  import Jason

  def append_new_entry(agent_name, messages, response) do
    Tape.Writer.acquire(fn -> new_append(agent_name, messages, response) end)
  end

  def write_new_entry(agent_name, messages, response) do
    Tape.Writer.acquire(fn -> new_write(agent_name, messages, response) end)
  end

  def append_old_entry(messages, response) do
    Tape.Writer.acquire(fn -> old_append(messages, response) end)
  end

  def write_old_entry(messages, response) do
    Tape.Writer.acquire(fn -> old_write(messages, response) end)
  end

  defp new_append(agent_name, messages, response) do
    entries = Tape.Store.load_entries()
    save_entries(entries ++ [[agent_name, encode!(messages), response]], true)
  end

  defp new_write(agent_name, messages, response) do
    save_entries([[agent_name, encode!(messages), response]], true)
  end

  defp old_append(messages, response) do
    cassette = Tape.Store.load_old_entries()
    key = Tape.Store.content_key(messages)
    save_old_entries(Map.put(cassette, key, response))
  end

  defp old_write(messages, response) do
    key = Tape.Store.content_key(messages)
    save_old_entries(%{key => response})
  end

  defp save_entries(data, pretty) do
    File.mkdir_p(cassette_dir())
    File.write(cassette_file(), encode!(data, pretty: pretty))
  end

  defp save_old_entries(data) do
    File.mkdir_p(cassette_dir())
    File.write(cassette_file(), encode!(data))
  end

  defp cassette_file do
    "test/cassettes/#{System.get_env("CASSETTE")}.json"
  end

  defp cassette_dir do
    "test/cassettes"
  end
end
