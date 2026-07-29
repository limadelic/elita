defmodule Elita do
  use GenServer

  import Cfgs, only: [load: 1]
  import History, only: [record: 1]
  import Llm, only: [llm: 1]
  import Map, only: [merge: 2, get: 2]
  import Mem, only: [create: 1]
  import Msg, only: [user: 1]
  import Reply, only: [deliver: 2]
  import String, only: [trim: 1]
  import Keyword, only: [get: 3]
  import Utils.Normalize, only: [name: 1]
  import Process, only: [flag: 2]
  import Tools

  defdelegate spawn(name, configs), to: Elita.Boot
  defdelegate spawn(name, configs, opts), to: Elita.Boot
  defdelegate prime(), to: Elita.Boot
  defdelegate dispatch(name, msg), to: Elita.Boot
  defdelegate request(name, msg), to: Elita.Boot

  @impl true
  def init({name, configs}), do: init({name, configs, [sender: name]})

  @impl true
  def init({name, configs, opts}) do
    normalized = name(name)
    register({normalized, :puppet}, opts, name, configs)
  end

  defp register(key, opts, name, configs) do
    :global.register_name(key, self())
    |> proceed(opts, name, configs)
  end

  defp proceed(:yes, opts, name, configs) do
    setup(opts, name, configs)
  end

  defp proceed(:no, _opts, _name, _configs) do
    {:stop, :duplicate}
  end

  defp setup(opts, name, configs) do
    flag(:trap_exit, true)
    settings = get(opts, :tape_env, %{})
    create(name)
    seed(get(settings, :tape))
    {:ok, state(name, configs, opts, settings)}
  end

  defp state(name, configs, opts, settings) do
    %{name: name, config: load(configs), history: [], configs: configs}
    |> merge(settings)
    |> merge(build(opts, name))
  end

  defp build(opts, name) do
    %{sender: get(opts, :sender, name), skip_logs: get(opts, :skip_logs, false)}
  end

  defp seed(nil), do: :ok
  defp seed(_), do: :rand.seed(:exsss, {1, 2, 3})

  @impl true
  def handle_call({:ask, msg}, from, state) do
    handle_call({:act, msg}, from, state)
  end

  @impl true
  def handle_call({:act, msg}, _, state) do
    act(msg, state)
  end

  @impl true
  def handle_cast({:act, msg}, state) do
    {_, _, state} = act(msg, state)
    {:noreply, state}
  end

  defp act(msg, %{configs: configs, history: history} = state) do
    history = branch("judge" in configs, history, user(msg))
    act(%{state | history: history})
  end

  defp branch(true, _, msg), do: [msg]
  defp branch(false, history, msg), do: history ++ [msg]

  defp act(state) do
    state |> llm() |> exec() |> record() |> done()
  end

  defp done({:act, state}), do: act(state)

  defp done({:reply, txt, %{name: name} = state}) do
    deliver(name, trim(txt))
    {:reply, trim(txt), state}
  end

  @impl true
  def terminate(_reason, state) do
    key = {name(state.name), :puppet}
    :global.whereis_name(key) |> sweep(key)
  end

  defp sweep(pid, key) when pid == self(), do: :global.unregister_name(key)
  defp sweep(_pid, _key), do: :ok
end
