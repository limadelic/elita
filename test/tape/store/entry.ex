defmodule Tape.Store.Entry do
  import Jason

  def append_new_entry(agent_name, messages, response) do
    Tape.Writer.acquire(fn -> new_append(agent_name, messages, response) end)
  end

  def write_new_entry(agent_name, messages, response) do
    Tape.Writer.acquire(fn -> new_write(agent_name, messages, response) end)
  end

  defp new_append(agent_name, messages, response) do
    entries = Tape.Store.load_entries()
    save_entries(entries ++ [[agent_name, encode!(messages), response]], true)
  end

  defp new_write(agent_name, messages, response) do
    save_entries([[agent_name, encode!(messages), response]], true)
  end

  defp save_entries(data, pretty) do
    File.mkdir_p(cassette_dir())
    File.write(cassette_file(), encode!(data, pretty: pretty))
  end

  defp cassette_file do
    "test/cassettes/#{System.get_env("CASSETTE")}.json"
  end

  defp cassette_dir do
    "test/cassettes"
  end
end
