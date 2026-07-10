defmodule Agent.Session do
  use GenServer

  import Agent.Spawn, only: [run: 2]
  import GenServer, only: [start_link: 3, call: 3]
  import Keyword, only: [fetch!: 2, get: 3]
  import Map, only: [put: 3]
  import String, only: [downcase: 1]
  import Tape, only: [handle: 3]

  def start_link(opts) do
    folder = fetch!(opts, :folder)
    normalized = normalize(opts)
    via = via(normalized, folder)
    start_link(__MODULE__, opts, name: via)
  end

  defp normalize(opts) do
    fetch!(opts, :name) |> to_string() |> downcase()
  end

  defp via(normalized, folder) do
    metadata = %{kind: :headless, folder: folder}
    {:via, Registry, {ElitaRegistry, normalized, metadata}}
  end

  def ask(pid, message), do: call(pid, {:ask, message}, :infinity)
  def cast(pid, message), do: GenServer.cast(pid, {:cast, message})
  def fetch(pid), do: call(pid, :fetch, :infinity)
  @impl true
  def init(opts) do
    {:ok, state(opts)}
  end

  defp state(opts) do
    %{name: fetch!(opts, :name), folder: fetch!(opts, :folder)}
    |> put(:self, get(opts, :self, nil))
    |> put(:runner, get(opts, :runner, &run/2))
  end

  @impl true
  def handle_call({:ask, message}, _from, state) do
    body = %{messages: [%{content: message}]}
    response = handle(body, state.name, fn -> state.runner.(message, state.folder) end)
    {:reply, {:ok, response}, state}
  end

  def handle_call({:act, message}, _from, state) do
    response = state.runner.(message, state.folder)
    {:reply, response, state}
  end

  def handle_call(:fetch, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:cast, message}, state) do
    state.runner.(message, state.folder)
    {:noreply, state}
  end
end
