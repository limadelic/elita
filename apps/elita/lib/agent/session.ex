defmodule Agent.Session do
  use GenServer

  import Agent.Spawn, only: [run: 2]
  import GenServer, only: [start_link: 3, call: 3]
  import Keyword, only: [fetch!: 2, get: 3]
  import String, only: [downcase: 1]

  def start_link(opts) do
    folder = Keyword.fetch!(opts, :folder)
    normalized = Keyword.fetch!(opts, :name) |> to_string() |> downcase()
    metadata = %{kind: :headless, folder: folder}
    via_name = {:via, Registry, {ElitaRegistry, normalized, metadata}}
    start_link(__MODULE__, opts, name: via_name)
  end

  def ask(pid, message), do: call(pid, {:ask, message}, :infinity)
  def cast(pid, message), do: GenServer.cast(pid, {:cast, message})
  def fetch(pid), do: call(pid, :fetch, :infinity)
  @impl true
  def init(opts) do
    name = fetch!(opts, :name)
    folder = fetch!(opts, :folder)
    self = get(opts, :self, nil)
    runner = get(opts, :runner, &run/2)
    {:ok, %{name: name, folder: folder, self: self, runner: runner}}
  end

  @impl true
  def handle_call({:ask, message}, _from, state) do
    response = state.runner.(message, state.folder)
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
