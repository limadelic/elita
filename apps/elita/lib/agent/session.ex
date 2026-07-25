defmodule Agent.Session do
  use GenServer

  import Agent.Spawn, only: [run: 2]
  import Agent.Ask, only: [reply: 5]
  import Agent.Log, only: [reply: 1]
  import GenServer, only: [start_link: 3, call: 3, cast: 2]
  import Keyword, only: [fetch!: 2, get: 3]
  import Map, only: [put: 3]
  import String, only: [downcase: 1]

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
  def forward(pid, message), do: cast(pid, {:cast, message})
  def fetch(pid), do: call(pid, :fetch, :infinity)

  @impl true
  def init(opts) do
    {:ok, state(opts)}
  end

  defp state(opts) do
    %{name: fetch!(opts, :name), folder: fetch!(opts, :folder)}
    |> put(:self, get(opts, :self, nil))
    |> put(:runner, get(opts, :runner, &run/2))
    |> put(:skip_logs, get(opts, :skip_logs, false))
  end

  @impl true
  def handle_call({:ask, message}, _from, state) do
    body = %{messages: [%{content: message}]}
    response = process(message, state, body)
    {:reply, {:ok, response}, state}
  end

  @impl true
  def handle_call({:act, message}, _from, state) do
    response = state.runner.(message, state.folder)
    {:reply, response, state}
  end

  @impl true
  def handle_call(:fetch, _from, state) do
    {:reply, state, state}
  end

  defp process("log", state, _body) do
    reply(state.name)
  end

  defp process(message, state, body) do
    reply(state.name, message, body, state.folder, state.runner)
  end

  @impl true
  def handle_cast({:cast, message}, state) do
    state.runner.(message, state.folder)
    {:noreply, state}
  end
end
