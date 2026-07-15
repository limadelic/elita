defmodule Elita do
  use GenServer

  import Cfgs, only: [load: 1]
  import GenServer, only: [call: 3, cast: 2, start_link: 3]
  import History, only: [record: 1]
  import Llm, only: [llm: 1]
  import Mem, only: [create: 0]
  import Msg, only: [user: 1]
  import String, only: [downcase: 1, trim: 1]
  import System, only: [get_env: 1]
  import Tools

  def spawn(name, configs) do
    {:ok, pid} = started(__MODULE__, {name, configs}, via(name))
    publish(name)
    {:ok, pid}
  end

  defp started(m, a, k), do: start_link(m, a, name: k) |> accept()

  defp accept({:ok, p}), do: {:ok, p}
  defp accept({:error, {:already_started, p}}), do: {:ok, p}

  defp publish(name) do
    publish(name, :global.whereis_name({name, :puppet}))
  end

  defp publish(name, :undefined) do
    :global.register_name({name, :puppet}, self())
  end

  defp publish(_name, _pid), do: :ok

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

  def init({name, configs}) do
    create()
    seed()
    {:ok, %{name: name, config: load(configs), history: [], configs: configs}}
  end

  defp seed do
    get_env("TAPE")
    |> prime()
  end

  defp prime(nil), do: :ok
  defp prime(_), do: :rand.seed(:exsss, {1, 2, 3})

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

  defp branch(true, _, msg), do: [msg]
  defp branch(false, history, msg), do: history ++ [msg]

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
    answer(name, txt)
    {:reply, txt, state}
  end
  defp answer(agent, text) do
    :erlang.apply(:"Elixir.Tools.Sys.Ask", :answer, [agent, text])
  rescue
    _ -> :ok
  end
end
