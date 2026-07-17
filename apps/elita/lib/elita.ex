defmodule Elita do
  use GenServer

  import Cfgs, only: [load: 1]
  import History, only: [record: 1]
  import Llm, only: [llm: 1]
  import Map, only: [merge: 2]
  import Mem, only: [create: 0]
  import Msg, only: [user: 1]
  import Reply, only: [deliver: 2]
  import String, only: [trim: 1]
  import System, only: [get_env: 1]
  import Tools

  defdelegate spawn(name, configs), to: Elita.Boot
  defdelegate spawn(name, configs, opts), to: Elita.Boot
  defdelegate prime(), to: Elita.Boot
  defdelegate dispatch(name, msg), to: Elita.Boot
  defdelegate request(name, msg), to: Elita.Boot

  def init({name, configs}), do: init({name, configs, [sender: name]})

  def init({name, configs, opts}) do
    create()
    seed()
    {:ok, state(name, configs, opts)}
  end

  defp state(name, configs, opts) do
    base = %{name: name, config: load(configs), history: [], configs: configs}
    merge(base, %{sender: sender(opts, name), skip_logs: skip(opts)})
  end

  defp sender(opts, name), do: Keyword.get(opts, :sender, name)
  defp skip(opts), do: Keyword.get(opts, :skip_logs, false)

  defp seed do
    get_env("TAPE") |> tape()
  end

  defp tape(nil), do: :ok
  defp tape(_), do: :rand.seed(:exsss, {1, 2, 3})

  def handle_call({:ask, msg}, from, state) do
    handle_call({:act, msg}, from, state)
  end

  def handle_call({:act, msg}, _, state) do
    act(msg, state)
  end

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
end
