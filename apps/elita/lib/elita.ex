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
  import Elita.Enlist, only: [handle: 4, cleanup: 1]
  import Elita.Vault, only: [restore: 1, save: 2]
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
    with {:ok, opts, name, configs} <-
           handle({name(name), :puppet}, opts, name, configs) do
      prepare(opts, name, configs)
    end
  end

  defp prepare(opts, name, configs) do
    flag(:trap_exit, true)
    setup(opts, name, configs)
  end

  defp setup(opts, name, configs) do
    settings = get(opts, :tape_env, %{})
    create(name)
    seed(get(settings, :tape))
    {:ok, state(name, configs, opts, settings)}
  end

  defp state(name, configs, opts, settings) do
    base = base(name, configs)
    sender = get(opts, :sender, name)
    skip = get(opts, :skip_logs, false)
    merge(merge(base, settings), %{sender: sender, skip_logs: skip})
  end

  defp base(name, configs) do
    history = restore(name)
    %{name: name, config: load(configs), history: history, configs: configs}
  end

  defp seed(nil), do: :ok
  defp seed(_), do: :rand.seed(:exsss, {1, 2, 3})
  @impl true
  def handle_call({:ask, msg}, from, state), do: handle_call({:act, msg}, from, state)
  @impl true
  def handle_call({:act, msg}, _, state), do: act(msg, state)
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

  defp done({:reply, txt, %{name: name, history: history} = state}) do
    deliver(name, trim(txt))
    save(name, history)
    {:reply, trim(txt), state}
  end

  @impl true
  def terminate(_reason, state) do
    cleanup(state)
  end
end
