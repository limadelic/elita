defmodule Elita do
  use GenServer

  import Cfgs, only: [config: 1]
  import Lite, only: [llm: 2]
  import Mem, only: [create: 0]
  import Tools
  import History, only: [record: 1]
  import Msg, only: [user: 1]
  import Log, only: [reply: 2]
  import Ink, only: [flush: 1]
  import String, only: [downcase: 1, trim: 1]
  import System, only: [get_env: 1]
  import Out, only: [assist: 1, flush: 0]
  import IO, only: [write: 2]
  import Enum, only: [each: 2]

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
    {:via, Registry, {ElitaRegistry, downcase(name)}}
  end

  def init({name, configs}) do
    create()
    {:ok, %{name: name, config: config(configs), history: []}}
  end

  def handle_call({:act, msg}, _, state) do
    act(msg, state)
  end

  def handle_cast({:act, msg}, state) do
    {_, _, state} = act(msg, state)
    {:noreply, state}
  end

  defp act(msg, %{history: history} = state) do
    history = [user(msg) | history]
    act(%{state | history: history})
  end

  defp act(state) do
    state
    |> llm(mode())
    |> exec
    |> record
    |> done
  end

  defp mode do
    case get_env("ELITA_STREAM") do
      nil -> Application.get_env(:elita, :stream, :render)
      v -> parse(v)
    end
  end

  defp parse(v) do
    case downcase(trim(v)) do
      "silent" -> :silent
      "stdout" -> :stdout
      "render" -> :render
      _ -> Application.get_env(:elita, :stream, :render)
    end
  end

  defp done({:act, state}) do
    act(state)
  end

  defp done({:reply, txt, %{streamed: true} = state}) do
    txt = trim(txt)
    ink_flush(state)
    flush()
    {:reply, txt, Map.drop(state, [:streamed, :ink])}
  end

  defp done({:reply, txt, %{name: name} = state}) do
    txt = trim(txt)
    reply(name, txt)
    flush()
    {:reply, txt, state}
  end

  def terminate(_reason, %{defined: agents}) do
    each(agents, &reap/1)
  end

  def terminate(_, _), do: :ok

  defp reap(name) do
    :ets.delete(:elita_agents, {:agent, name})
    :ets.delete(:elita_agents, name)
    GenServer.stop(via(name))
  rescue
    _ -> :ok
  end

  defp ink_flush(state) do
    case Map.get(state, :ink) do
      nil ->
        assist("\n")

      ink ->
        flush(ink)
        write(:stderr, "\n")
    end
  end
end
