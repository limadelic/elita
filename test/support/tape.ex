defmodule Tape do
  import File, only: [write: 2, read!: 1, exists?: 1, mkdir_p: 1]
  import System, only: [get_env: 1]
  import Jason, only: [encode!: 1, decode!: 1]
  import Map, only: [fetch: 2, put: 3]

  def play(body, request_fun) do
    case get_env("TAPE") do
      "record" -> record(body, request_fun)
      _ -> replay_or_record(body, request_fun)
    end
  end

  defp replay_or_record(body, request_fun) do
    cassette = read_cassette_safe()
    key = compute_key(body)
    case fetch(cassette, key) do
      {:ok, content} -> content
      :error -> record(body, request_fun)
    end
  end

  defp read_cassette_safe do
    path = cassette_file()
    existing_cassette(path)
  end

  defp record(body, fun) do
    result = fun.()
    key = compute_key(body)
    write_cassette(key, result)
    result
  end

  defp compute_key(body) do
    messages = body[:messages] || []
    :erlang.phash2(messages) |> to_string()
  end

  defp write_cassette(key, entry) do
    path = cassette_file()
    mkdir_p(cassette_dir())
    cassette = existing_cassette(path)
    updated = put(cassette, key, entry)
    write(path, encode!(updated))
  end

  defp existing_cassette(path) do
    if exists?(path) do
      path |> read!() |> decode!()
    else
      %{}
    end
  end

  defp cassette_file do
    "test/cassettes/#{get_env("CASSETTE")}.json"
  end

  defp cassette_dir do
    "test/cassettes"
  end
end
