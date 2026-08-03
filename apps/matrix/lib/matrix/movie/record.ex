defmodule Matrix.Movie.Record do
  @moduledoc false
  import System, only: [get_env: 1]
  import File, only: [read: 1, write: 2]
  import Map, only: [get: 3, put: 3]
  import Path, only: [join: 2]
  import Agent, only: [start_link: 2, get: 2, update: 2, stop: 1]
  import Enum, only: [map: 2]
  import Base, only: [encode64: 1]
  import Jason, only: [encode!: 2, decode!: 1]

  def active? do
    get_env("TAPE") == "rec"
  end

  def start(_pty_pid, name) do
    init = %{name: name, chunks: [], index: 0}
    {:ok, acc_pid} = start_link(fn -> init end, [])
    acc_pid
  end

  def record(acc_pid, data) when is_pid(acc_pid) do
    update(acc_pid, &append(data, &1))
  end

  def get(acc_pid) when is_pid(acc_pid) do
    get(acc_pid, & &1)
  end

  def done(acc_pid) when is_pid(acc_pid) do
    state = get(acc_pid, & &1)
    stop(acc_pid)
    save(state)
  end

  defp append(data, state) do
    chunk = %{i: state.index, chunk: data}
    %{state | chunks: state.chunks ++ [chunk], index: state.index + 1}
  end

  defp save(%{name: name, chunks: chunks}) do
    active?() && flush(name, chunks)
  end

  defp flush(name, chunks) do
    path = file()
    data = peek(path)
    merged = put(data, "movies", put(get(data, "movies", %{}), name, encode(chunks)))
    write(path, encode!(merged, pretty: true))
  end

  defp file do
    cassette = get_env("CASSETTE")
    dir = dir()
    join(dir, "#{cassette}.json")
  end

  defp dir, do: get_env("CASSETTE_DIR") || "test/cassettes"

  defp peek({:ok, content}) do
    decode!(content)
  end

  defp peek({:error, _}) do
    %{}
  end

  defp peek(path) do
    read(path) |> peek()
  end

  defp encode(chunks) do
    map(chunks, fn %{chunk: data} -> encode64(data) end)
  end
end
