defmodule Elita do
  use GenServer

  import Cfgs, only: [load: 1]
  import History, only: [record: 1]
  import Llm, only: [llm: 1]
  import Map, only: [merge: 2]
  import Mem, only: [create: 1]
  import Msg, only: [user: 1]
  import Reply, only: [deliver: 2]
  import String, only: [trim: 1]
  import System, only: [get_env: 1, put_env: 2]
  import Keyword, only: [get: 3]
  import Enum, only: [each: 2]
  import Tools

  defdelegate spawn(name, configs), to: Elita.Boot
  defdelegate spawn(name, configs, opts), to: Elita.Boot
  defdelegate prime(), to: Elita.Boot
  defdelegate dispatch(name, msg), to: Elita.Boot
  defdelegate request(name, msg), to: Elita.Boot

  def init({name, configs}), do: init({name, configs, [sender: name]})

  def init({name, configs, opts}) do
    inject(opts)
    create(name)
    seed()
    {:ok, state(name, configs, opts)}
  end

  defp inject(opts) do
    each(get(opts, :tape_env, %{}), &set/1)
  end

  defp set({:tape, v}), do: assign(:tape, v)
  defp set({:live, v}), do: assign(:live, v)
  defp set({:cassette, v}), do: assign(:cassette, v)
  defp set({:cassette_dir, v}), do: assign(:cassette_dir, v)

  defp assign(_, nil), do: :ok
  defp assign(:tape, v), do: put_env("TAPE", v)
  defp assign(:live, v), do: put_env("LIVE", v)
  defp assign(:cassette, v), do: put_env("CASSETTE", v)
  defp assign(:cassette_dir, v), do: put_env("CASSETTE_DIR", v)

  defp state(name, configs, opts) do
    base = %{name: name, config: load(configs), history: [], configs: configs}
    merge(base, %{sender: sender(opts, name), skip_logs: skip(opts)})
  end

  defp sender(opts, name), do: get(opts, :sender, name)
  defp skip(opts), do: get(opts, :skip_logs, false)

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
