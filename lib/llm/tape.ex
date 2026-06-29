defmodule Tape do
  import File, only: [write: 2, read!: 1, exists?: 1, mkdir_p: 1]
  import System, only: [get_env: 1]
  import Jason, only: [encode!: 1, decode!: 1]

  def play(request_fun) do
    case get_env("TAPE") do
      "record" -> record(request_fun)
      "replay" -> replay()
      _ -> request_fun.()
    end
  end

  defp record(fun) do
    result = fun.()
    write_cassette(result)
    result
  end

  defp replay do
    init_ets()
    entries = read_cassette()
    pos = get_position()
    if pos < length(entries) do
      entry = Enum.at(entries, pos)
      bump_position()
      entry
    else
      {:error, "cassette exhausted at position #{pos}"}
    end
  end

  defp write_cassette(entry) do
    path = cassette_file()
    mkdir_p(cassette_dir())
    entries = existing_entries(path)
    updated = entries ++ [entry]
    write(path, encode!(updated))
  end

  defp read_cassette do
    cassette_file() |> read!() |> decode!()
  end

  defp existing_entries(path) do
    if exists?(path) do
      path |> read!() |> decode!()
    else
      []
    end
  end

  defp get_position do
    case :ets.lookup(:tape, :position) do
      [{:position, pos}] -> pos
      [] -> 0
    end
  end

  defp bump_position do
    :ets.update_counter(:tape, :position, {2, 1})
  end

  defp init_ets do
    case :ets.whereis(:tape) do
      :undefined ->
        :ets.new(:tape, [:named_table, :public])
        :ets.insert(:tape, {:position, 0})

      _ ->
        :ok
    end
  end

  defp cassette_file do
    "test/cassettes/#{get_env("CASSETTE")}.json"
  end

  defp cassette_dir do
    "test/cassettes"
  end
end
