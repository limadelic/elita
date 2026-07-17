defmodule Elita do
  use GenServer

  import Cfgs, only: [load: 1]
  import GenServer, only: [call: 3, cast: 2, start_link: 3]
  import History, only: [record: 1]
  import Llm, only: [llm: 1]
  import Mem, only: [create: 0]
  import Msg, only: [user: 1]
  import Reply, only: [deliver: 2]
  import String, only: [downcase: 1, trim: 1]
  import System, only: [get_env: 1]
  import Tools

  def spawn(name, configs, opts \\ []) do
    opts = norm(opts, name)
    {:ok, pid} = started(__MODULE__, {name, configs, opts}, via(name))
    publish(name, pid)
    {:ok, pid}
  end

  defp norm([], name), do: [sender: name]
  defp norm(opts, _), do: opts

  defp started(m, a, k) do
    start_link(m, a, name: k) |> join()
  end

  defp join({:ok, p}), do: {:ok, p}
  defp join({:error, {:already_started, p}}), do: {:ok, p}

  defp publish(name, pid) do
    :global.whereis_name({name, :puppet}) |> reg(name, pid)
  end

  defp reg(:undefined, name, pid), do: :global.register_name({name, :puppet}, pid)
  defp reg(_, _, _), do: :ok
  def dispatch(name, msg) do
    cast(via(name), {:act, msg})
  end

  def request(name, msg) do
    call(via(name), {:act, msg}, :infinity)
  end

  defp via(name) do
    normalized = name |> to_string() |> downcase()
    {:via, Registry, {ElitaRegistry, normalized, %{kind: :native, folder: nil}}}
  end
  def init({name, configs}), do: init({name, configs, [sender: name]})

  def init({name, configs, opts}) do
    create()
    seed()
    {:ok, state(name, configs, opts)}
  end

  defp state(name, configs, opts) do
    %{name: name, config: load(configs), history: [], configs: configs,
      sender: Keyword.get(opts, :sender, name),
      skip_logs: Keyword.get(opts, :skip_logs, false)}
  end

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
