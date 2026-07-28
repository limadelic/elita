defmodule Agent.Watch do
  import String, only: [trim: 1]
  import System, only: [monotonic_time: 1]
  import Agent.Jsonl, only: [find: 3]
  import Agent.Puppet, only: [cwd: 0]
  import Log, only: [trace: 1]
  import Task.Supervisor, only: [start_child: 2]

  def start(agent, question, folder \\ nil) do
    start_child(Elita.Tasks, fn -> init(agent, question, folder) end)
  end

  defp init(agent, question, folder) do
    boot(agent, question, resolve(folder))
  rescue
    e -> reraise e, __STACKTRACE__
  end

  defp resolve(nil), do: cwd()
  defp resolve(folder), do: folder

  defp boot(agent, question, folder) do
    trace("WATCHER START #{agent} #{question}\n")
    trace("watcher:folder=#{inspect(folder)}\n")
    {agent, question, folder, monotonic_time(:millisecond), 0} |> loop()
  end

  defp loop({_, _, _, start, _pos} = state) do
    elapsed = monotonic_time(:millisecond) - start
    proceed(state, elapsed)
  end

  defp proceed(_, elapsed) when elapsed > 90000, do: :ok

  defp proceed({agent, question, folder, start, pos}, _) do
    {agent, question, folder, start, pos} |> fetch()
  end

  defp fetch({_agent, question, folder, _start, pos} = state) do
    check(scan(question, folder, pos), state)
  end

  defp check({:found, text}, {agent, _, _, _, _}) do
    answer(agent, trim(text))
  end

  defp check({:continue, newpos}, {agent, q, f, s, _}) do
    wait(agent, q, f, s, newpos)
  end

  defp check(:wait, {agent, q, f, s, p}) do
    wait(agent, q, f, s, p)
  end

  defp wait(agent, question, folder, start, pos) do
    receive do
    after
      100 -> loop({agent, question, folder, start, pos})
    end
  end

  defp scan(question, folder, pos) do
    guard(find(question, folder, pos))
  end

  defp guard(result) do
    result
  catch
    :exit, e -> oops(:exit, e)
    k, r -> oops(k, r)
  end

  defp oops(:exit, e) do
    trace("WATCHER CATCH EXIT #{inspect(e)}\n")
    :wait
  end

  defp oops(k, r) do
    trace("WATCHER CATCH #{k} #{inspect(r)}\n")
    :wait
  end

  defp answer(agent, text) do
    :erlang.apply(:"Elixir.Tools.Sys.Ask", :answer, [agent, text])
  rescue
    _ -> :ok
  end
end
