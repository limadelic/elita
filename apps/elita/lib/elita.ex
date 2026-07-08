defmodule Elita do
  use GenServer

  import Cfgs, only: [config: 1]
  import History, only: [record: 1]
  import Llm, only: [llm: 1]
  import Log, only: [log: 5]
  import Mem, only: [create: 0]
  import Msg, only: [user: 1]
  import String, only: [downcase: 1, trim: 1]
  import System, only: [get_env: 1]
  import Tools

  def start_link(name, configs) do
    GenServer.start_link(__MODULE__, {name, configs}, name: via(name))
  end

  def cast(name, msg) do
    GenServer.cast(via(name), {:act, msg})
  end

  def call(name, msg) do
    GenServer.call(via(name), {:act, msg}, :infinity)
  end

  defp via(name) do
    normalized = name |> to_string() |> downcase()
    {:via, Registry, {ElitaRegistry, normalized, %{kind: :native, folder: nil}}}
  end

  def init({name, configs}) do
    create()
    tape_seed()
    {:ok, %{name: name, config: config(configs), history: [], configs: configs}}
  end

  defp tape_seed do
    get_env("TAPE")
    |> maybe_seed()
  end

  defp maybe_seed(nil), do: :ok
  defp maybe_seed(_), do: :rand.seed(:exsss, {1, 2, 3})

  def handle_call({:act, msg}, _, state) do
    act(msg, state)
  end

  def handle_cast({:act, msg}, state) do
    {_, _, state} = act(msg, state)
    {:noreply, state}
  end

  defp act(msg, %{configs: configs, history: history} = state) do
    history = branch(judge?(configs), history, user(msg))
    act(%{state | history: history})
  end

  defp branch(true, _history, msg) do
    [msg]
  end

  defp branch(false, history, msg) do
    history ++ [msg]
  end

  defp judge?(configs) do
    "judge" in configs
  end

  defp act(state) do
    state |> llm() |> exec() |> record() |> done()
  end

  defp done({:act, state}) do
    act(state)
  end

  defp done({:reply, txt, %{name: name} = state}) do
    txt = trim(txt)
    log("✨", name, ": ", txt, :white)
    {:reply, txt, state}
  end
end
